var mongoose = require('mongoose');
var Schema = mongoose.Schema;
const bcrypt = require('bcryptjs');

var schema = new Schema({
    active: Boolean,
    email: { type: String, required: true, lowercase: true, trim: true, index: { unique: true } },
    username: { type: String, required: true, lowercase: true, trim: true, index: { unique: true } },
    password: { type: String, required: true, select: false }
}, { timestamps: true });

schema.methods.verifyPassword = function(password) {
    return bcrypt.compareSync(password, this.password);
};

schema.pre('save', async function() {
    if (!this.isModified('password')) return;
    this.password = bcrypt.hashSync(this.password, 10); // 10 - salt work factor
});

var User = mongoose.model('User', schema);

module.exports = User;
