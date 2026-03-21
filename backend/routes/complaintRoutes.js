const express = require('express');
const router = express.Router();
const Complaint = require('../models/Complaint');
const { verifyJWT, checkRole } = require('../middleware/auth');
const { calculateDistance } = require('../utils/geoUtils');

// Create Complaint (Citizen only)
router.post('/', verifyJWT, checkRole(['user']), async (req, res) => {
  try {
    const { title, description, image, location } = req.body;
    const complaint = new Complaint({
      title,
      description,
      image,
      location,
      createdBy: req.user.userId,
      status: 'PENDING'
    });
    await complaint.save();
    res.status(201).json(complaint);
  } catch (error) {
    res.status(500).json({ message: 'Error creating complaint', error });
  }
});

// Get Complaints (Role-based filtering)
router.get('/', verifyJWT, async (req, res) => {
  try {
    let query = {};
    if (req.user.role === 'user') {
      query.createdBy = req.user.userId;
    } else if (req.user.role === 'engineer') {
      query.assignedEngineerId = req.user.userId;
    }
    // Admin sees all
    const complaints = await Complaint.find(query).populate('createdBy', 'name').populate('assignedEngineerId', 'name');
    res.json(complaints);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching complaints' });
  }
});

// Verify (Admin only)
router.put('/:id/verify', verifyJWT, checkRole(['admin']), async (req, res) => {
  try {
    const complaint = await Complaint.findById(req.params.id);
    if (!complaint) return res.status(404).json({ message: 'Not found' });
    if (complaint.status !== 'PENDING') return res.status(400).json({ message: 'Invalid state transition' });

    complaint.status = 'VERIFIED';
    complaint.verifiedAt = new Date();
    await complaint.save();
    res.json(complaint);
  } catch (error) {
    res.status(500).json({ message: 'Error verifying complaint' });
  }
});

// Assign (Admin only)
router.put('/:id/assign', verifyJWT, checkRole(['admin']), async (req, res) => {
  try {
    const { engineerId } = req.body;
    const complaint = await Complaint.findById(req.params.id);
    if (!complaint) return res.status(404).json({ message: 'Not found' });
    if (complaint.status !== 'VERIFIED') return res.status(400).json({ message: 'Must be verified first' });

    complaint.status = 'ASSIGNED';
    complaint.assignedEngineerId = engineerId;
    complaint.assignedAt = new Date();
    await complaint.save();
    res.json(complaint);
  } catch (error) {
    res.status(500).json({ message: 'Error assigning complaint' });
  }
});

// Resolve (Engineer only)
router.put('/:id/resolve', verifyJWT, checkRole(['engineer']), async (req, res) => {
  try {
    const { resolutionImage, currentLocation } = req.body;
    const complaint = await Complaint.findById(req.params.id);
    if (!complaint) return res.status(404).json({ message: 'Not found' });
    if (complaint.status !== 'ASSIGNED') return res.status(400).json({ message: 'Must be assigned first' });

    // Distance check
    const distance = calculateDistance(
      complaint.location.latitude,
      complaint.location.longitude,
      currentLocation.latitude,
      currentLocation.longitude
    );

    if (distance > 30) {
      return res.status(400).json({ message: `Too far! You are ${Math.round(distance)}m away. Must be within 30m.` });
    }

    complaint.status = 'RESOLVED';
    complaint.resolutionImage = resolutionImage;
    complaint.resolvedAt = new Date();
    await complaint.save();
    res.json(complaint);
  } catch (error) {
    res.status(500).json({ message: 'Error resolving complaint' });
  }
});

// Analytics (Admin only)
router.get('/analytics', verifyJWT, checkRole(['admin']), async (req, res) => {
  try {
    const total = await Complaint.countDocuments();
    const pending = await Complaint.countDocuments({ status: 'PENDING' });
    const resolved = await Complaint.countDocuments({ status: 'RESOLVED' });
    
    // Average resolution time
    const resolvedComplaints = await Complaint.find({ status: 'RESOLVED' });
    let totalTime = 0;
    resolvedComplaints.forEach(c => {
      totalTime += (c.resolvedAt - c.createdAt);
    });
    const avgTime = resolvedComplaints.length > 0 ? (totalTime / resolvedComplaints.length / (1000 * 60 * 60 * 24)).toFixed(2) : 0;

    res.json({ total, pending, resolved, avgTimeDays: avgTime });
  } catch (error) {
    res.status(500).json({ message: 'Error fetching analytics' });
  }
});

module.exports = router;
