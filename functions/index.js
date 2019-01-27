const functions = require('firebase-functions');
const admin = require('firebase-admin');
const app = require('express')

const config = functions.config().dev

const stripe = require('./stripe')

admin.initializeApp(functions.config().firebase);

exports.secondsSince1970 = function() {
    var secondsSince1970 = new Date().getTime() / 1000
    return Math.floor(secondsSince1970)
}

exports.createUniqueId = function() {
    var secondsSince1970 = exports.secondsSince1970()
    var randomId = Math.floor(Math.random() * 899999 + 100000)
    return `${secondsSince1970}-${randomId}`
}


// STRIPE //////////////////////////////////////////////////////////////////////////////////
// http functions
exports.ephemeralKeys = functions.https.onRequest((req, res) => {
    return stripe.ephemeralKeys(req, res, exports)
})

exports.validateStripeCustomer = functions.https.onRequest((req, res) => {
    return stripe.validateStripeCustomer(req, res, exports)
})

exports.savePaymentInfo = functions.https.onRequest((req, res) => {
    return stripe.savePaymentInfo(req, res, exports)
})

exports.stripeConnectRedirectHandler = functions.https.onRequest((req, res) => {
    return stripe.stripeConnectRedirectHandler(req, res, exports)
})

exports.getConnectAccountInfo = functions.https.onRequest((req, res) => {
    return stripe.getConnectAccountInfo(req, res, exports)
})

exports.createStripeConnectCharge = functions.https.onRequest((req, res) => {
    return stripe.createStripeConnectCharge(req, res, exports)
})

