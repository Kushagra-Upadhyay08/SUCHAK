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
    console.log('Registration Payload:', { name, role, employeeId });

    let user = await User.findOne({ name });
    if (user) {
      return res.status(400).json({ message: 'User already exists' });
    }

    let finalEmployeeId = employeeId;

    if (finalEmployeeId) {
      const existingEmployee = await User.findOne({ employeeId: finalEmployeeId });
      if (existingEmployee) {
        // Auto-increment logic
        console.log(`Employee ID ${finalEmployeeId} already in use. Finding next available ID...`);
        const allUsersWithId = await User.find({ employeeId: { $exists: true, $ne: null } });

        let maxId = 0;
        for (const u of allUsersWithId) {
          const numId = parseInt(u.employeeId, 10);
          if (!isNaN(numId) && numId > maxId) {
            maxId = numId;
          }
        }

        // If the duplicate ID was not a number (e.g. "admin_xyz"), maxId might be 0.
        // We will just assign maxId + 1. If it was "1", it becomes "2".
        if (maxId === 0 && !isNaN(parseInt(finalEmployeeId, 10))) {
          const parsed = parseInt(finalEmployeeId, 10);
          maxId = parsed;
          // but we know 'parsed' is taken. We need to find the actual max to be safe.
          // In fact, the loop above already found the global max numeric ID.
          // So we just use maxId from the loop. If someone passed "1" and it's taken,
          // the loop found maxId >= 1.
        }

        finalEmployeeId = (maxId + 1).toString();
        console.log(`Assigned new Employee ID: ${finalEmployeeId}`);
      }
    }

    const userData = { name, password, role };
    // Only add employeeId if it has a truthy value, preventing E11000 on null
    if (finalEmployeeId) {
      userData.employeeId = finalEmployeeId;
    }

    user = new User(userData);
    await user.save();

    const token = jwt.sign(
      { userId: user._id, role: user.role },
      process.env.JWT_SECRET || 'secretkey',
      { expiresIn: '7d' }
    );

    res.json({ token, user: { id: user._id, name, role, employeeId: user.employeeId }, message: finalEmployeeId !== employeeId ? `Assigned new Employee ID: ${user.employeeId}` : undefined });
  } catch (error) {
    res.status(500).json({ message: 'Server error: ' + error.message });
  }
});

// Get Engineers (Admin only)
router.get('/engineers', verifyJWT, checkRole(['admin']), async (req, res) => {
  console.log('GET /engineers request received from admin:', req.user.userId);
  try {
    const engineers = await User.find({ role: 'engineer' }).select('name employeeId role _id');
    console.log(`Found ${engineers.length} engineers`);
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
    res.json({ token, user: { id: user._id, name: user.name, role: user.role, employeeId: user.employeeId } });
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
});

// Get current user info (for auto-login)
router.get('/me', verifyJWT, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId).select('-password');
    if (!user) return res.status(404).json({ message: 'User not found' });
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
