Spree::CheckoutController.class_eval do
  # Initializing xero to use @xero variable
  before_action :get_xero

  def update
    if @order.update_from_params(params, permitted_checkout_attributes, request.headers.env)
      @order.temporary_address = !params[:save_user_address]
      unless @order.next
        flash[:error] = @order.errors.full_messages.join("\n")
        redirect_to(checkout_state_path(@order.state)) && return
      end

      if @order.completed?
        if !spree_current_user.xero_customer_id.nil?
          contact_id = spree_current_user.xero_customer_id
        else
          contact_id = create_xero_contact_and_return_contact_id
        end

        invoice = build_xero_invoice(contact_id)

        invoice = add_line_items_to_invoice(invoice)


        # Save the invoice
        puts "SAVING INVOICE =====>>>>"
        invoice.save

        # Optional
        # Invoice must be saved, in xero, before you can mark an invoice paid
        puts "MARKING INVOICE PAID =====>>>>"
        marke_invoice_as_paid(invoice)

        @current_order = nil
        flash.notice = Spree.t(:order_processed_successfully)
        flash['order_completed'] = true
        redirect_to completion_route
      else
        redirect_to checkout_state_path(@order.state)
      end
    else
      render :edit
    end
  end

  private
    # Creates a new contact for xero.
    # @see https://developer.xero.com/documentation/api/contacts#POST
    def create_xero_contact_and_return_contact_id
      user_address = spree_current_user.bill_address
      country_id = user_address.country_id

      contact = @xero.Contact.build(
        name:           user_address.firstname + " " + user_address.lastname, # Must be unique in xero!!!!!
        first_name:     user_address.firstname,
        last_name:       user_address.lastname,
        email_address:  spree_current_user.email,
      )

      # Include a contact address
      contact.add_address(
        type:           "STREET",
        line1:           user_address.address1,
        line2:           user_address.address2,
        city:            user_address.city,
        postal_code:     user_address.zipcode,
        country:         Spree::Country.find(country_id).name,
        # contact_number: user_address.phone # As of Xeroizer version 2.18
        # This will through an error undefined method [] for nil:NilClass
      )

      # Attached a contact number
      contact.add_phone(:type => 'DEFAULT', number: user_address.phone)

      # Save contact to your xero account.
      contact.save!

      # Update our spree_users table with the contact id for
      # future reference
      spree_current_user.update_attributes(xero_customer_id: contact.contact_id)

      # return the contact_id
      return contact.contact_id

    end

    def build_xero_invoice(contact_id)
      invoice =  @xero.Invoice.build(
        :type => "ACCREC",
        status: "AUTHORISED",
        currency_code: "GBP", # Change to your conuntry code
        reference: "Order " + @current_order.number,
        :contact => { contact_id: contact_id },
        sent_to_contact: false,
        date: DateTime.now,
        due_date: DateTime.now, # Change to your needs
      )

      return invoice
    end

    def add_line_items_to_invoice(invoice)
      @current_order.products.each do |product|
        # Amount is quantity times price. Integer values
        amount = product.line_items.first.quantity * product.line_items.first.price
        invoice.add_line_item(
          description:  product.name,
          quantity:     product.line_items.first.quantity,
          unit_amount:  amount,
          account_code: 200
        )
       end

       # Optional if you want shipping to be included on the invoice statement
       invoice.add_line_item(
         description: "Postage and packaging",
         quantity: 1,
         unit_amount: @current_order.shipment_total,
         account_code: 200
       )

       return invoice
    end

    def marke_invoice_as_paid(invoice)
      invoice_payment = {
        invoice:      invoice,
        account:      { code: '090' },
        date:         invoice.date,
        amount:       invoice.amount_due,
        payment_type: 'ACCRECPAYMENT'
      }
      payment = @xero.Payment.build(invoice_payment)
      payment.save
    end

    # Initializing Xeroizer with our public and private keys
    # found at https://developer.xero.com/myapps
    # @see https://developer.xero.com/documentation/api/api-overview
    def get_xero
      xero_config = Rails.application.credentials.xero
      consumer_key = xero_config[:consumer_key]
      consumer_secret = xero_config[:consumer_secret]

      # privatekey.pem file located at the root of your rails app
      privatekey_path = "#{Rails.root}/privatekey.pem"
      @xero = Xeroizer::PrivateApplication.new(consumer_key, consumer_secret, privatekey_path)
    end
end
