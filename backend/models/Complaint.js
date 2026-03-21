const mongoose = require('mongoose');

const complaintSchema = new mongoose.Schema({
  title: { type: String, required: true },
  description: { type: String, required: true },
  image: { type: String, required: true }, // Image URL or base64
  location: {
    latitude: { type: Number, required: true },
    longitude: { type: Number, required: true }
  },
  status: {
    type: String,
    enum: ['PENDING', 'VERIFIED', 'ASSIGNED', 'RESOLVED'],
    default: 'PENDING'
  },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  assignedEngineerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  verifiedAt: Date,
  assignedAt: Date,
  resolvedAt: Date,
  resolutionImage: String, // Proof from Engineer
}, { timestamps: true });

module.exports = mongoose.model('Complaint', complaintSchema);
