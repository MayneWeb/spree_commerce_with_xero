# Spree Commerce With Xero
Credits are due to the mentioned owners of all gems used. See links below. Created and inspired by [Daveyon Mayne](https://www.twitter.com/mirmayne) @ [MayneWeb](https://www.mayneweb.com). Copyright 2018. License: MIT.

## Introduction
This is a simple demonstration using Spree Commerce 3 tied with Xero to generate an invoice after a successful order from your storefront.

## How it works

This application acts as a "mini bookeeper". Once you've made an order from your Spree storefront, it creates an invoice for that customer then marks that invoice paid in your online Xero account.

Before creating an invoice, it checks your Xero account to see whether or not that customer is already in your Xero account then uses their details for the generated invoice. If not, it creates a new contact/customer for you.

## Private application

This application is configured for a private application only. Therefore you will need your `privatekey.pem` to be in the root of your application. See the `.gitignore` file.

## How to

We have written how to use this application in greater detail [here](https://www.mayneweb.com/p/spree-commerce-integrated-with-xero/).


## Dependencies

* Ruby version: 2.5.0

* [Spree Commerce Version: 3.5.6](https://github.com/spree/spree)

* [Xeroizer Version: 2.18.1](https://github.com/waynerobinson/xeroizer)

* PostgreSQL

* A Xero account
