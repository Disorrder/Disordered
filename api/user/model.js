var mongoose = require('mongoose');
var Schema = mongoose.Schema;

var schema = new Schema({
    active: Boolean,
    email: String,
    password: String
}, { timestamps: true });

var User = mongoose.model('User', schema);

module.exports = User;
