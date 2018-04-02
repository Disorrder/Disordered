var mongoose = require('mongoose');
var Schema = mongoose.Schema;
var ObjectId = mongoose.Schema.Types.ObjectId;
var Mixed = mongoose.Schema.Types.Mixed;

// var ratingSchema = new Schema({
//     active: Boolean,
//     chartId: ObjectId,
//     rating: Number,
//     time: Date,
// }, { timestamps: true });

var ratingSchema = {
    time: Date,
    value: Number
};

var chartSchema = new Schema({
    id: Number,
    active: Boolean,
    userId: ObjectId,
    ratings: [ratingSchema]
}, { timestamps: true });

var Chart = mongoose.model('Chart', schema);
// var Rating = mongoose.model('Rating', schema);

module.exports = User;
