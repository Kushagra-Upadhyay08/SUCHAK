const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const User = require('../models/User');
require('dotenv').config();

// Register
router.post('/register', async (req, res) => {
  try {
    console.log('1. Registration route hit');
    const { name, password, role } = req.body;
    console.log('2. Body parsed:', { name, role });
    
    console.log('3. Searching for user...');
    let user = await User.findOne({ name });
    console.log('4. User search complete');
    
    if (user) {
      console.log('5. User already exists');
      return res.status(400).json({ message: 'User already exists' });
    }

    console.log('6. Creating new user object...');
    user = new User({ name, password, role });
    console.log('7. Saving user to DB...');
    await user.save();
    console.log('8. User saved successfully');

    console.log('9. Signing token...');
    const token = jwt.sign({ userId: user._id, role: user.role }, process.env.JWT_SECRET || 'secretkey', { expiresIn: '7d' });
    console.log('10. Token signed');
    
    res.json({ token, user: { id: user._id, name, role } });
  } catch (error) {
    const fs = require('fs');
    fs.appendFileSync('error.log', error.stack + '\n');
    console.error('Registration error details saved to error.log');
    res.status(500).json({ message: 'Server error: ' + error.message });
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
