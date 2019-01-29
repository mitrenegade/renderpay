const functions = require('firebase-functions');
const admin = require('firebase-admin');
const app = require('express')
const globals = require('./globals')

admin.initializeApp(functions.config().firebase);

exports.getUniqueId = functions.https.onRequest( (req, res) => {
    var uniqueId = exports.createUniqueId()
    console.log('Called getUniqueId with result ' + uniqueId)
    res.status(200).json({"id": uniqueId})
})

// TEST calling cloud function from client
exports.sampleCloudFunction = functions.https.onRequest((req, res) => {
    const uid = req.body.uid
    const email = req.body.email

    // call this could function in the browser using this url:
    // https://us-central1-balizinha-dev.cloudfunctions.net/sampleCloudFunction?uid=123&email=456

    // the return must be a promise
    console.log("SampleCloudFunction called with parameters: uid " + uid + " email " + email)
    var ref = `/logs/SampleCloudFunction/${uid}`
    console.log("Sample cloud function logging with id " + uid + " email " + email)
    var params = {}
    params["email"] = email
    params["createdAt"] = exports.secondsSince1970()
    return admin.database().ref(ref).set(params).then(function (result) {
        console.log("Sample cloud function result " + result)
        return result
    }).then(function(result) {
        console.log("Sample cloud function did something else that returned " + JSON.stringify(result))
        return res.status(200).json({"success": true})
    })
})

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

