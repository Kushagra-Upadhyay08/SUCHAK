const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const User = require('../models/User');
require('dotenv').config();
const { verifyJWT, checkRole } = require('../middleware/auth');

// Register
router.post('/register', async (req, res) => {
  try {
    const { name, password, role, employeeId } = req.body;
    
    let user = await User.findOne({ name });
    if (user) {
      return res.status(400).json({ message: 'User already exists' });
    }

    if (employeeId) {
      const existingEmployee = await User.findOne({ employeeId });
      if (existingEmployee) {
        return res.status(400).json({ message: 'Employee ID already in use' });
      }
    }

    user = new User({ name, password, role, employeeId });
    await user.save();

    const token = jwt.sign(
      { userId: user._id, role: user.role }, 
      process.env.JWT_SECRET || 'secretkey', 
      { expiresIn: '7d' }
    );
    
    res.json({ token, user: { id: user._id, name, role, employeeId } });
  } catch (error) {
    res.status(500).json({ message: 'Server error: ' + error.message });
  }
});

// Get Engineers (Admin only)
router.get('/engineers', verifyJWT, checkRole(['admin']), async (req, res) => {
  try {
    const engineers = await User.find({ role: 'engineer' }).select('name employeeId _id');
    res.json(engineers);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching engineers' });
  }
});

// Login
router.post('/login', async (req, res) => {
  try {
    const { name, password } = req.body;
    const user = await User.findOne({ name });
    if (!user) return res.status(400).json({ message: 'Invalid credentials' });

    const isMatch = await user.comparePassword(password);
    if (!isMatch) return res.status(400).json({ message: 'Invalid credentials' });

    const token = jwt.sign({ userId: user._id, role: user.role }, process.env.JWT_SECRET || 'secretkey', { expiresIn: '7d' });
    res.json({ token, user: { id: user._id, name: user.name, role: user.role } });
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
