const mongoose = require('mongoose');
require('dotenv').config();

async function checkDb() {
  try {
    await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/suchak');
    const Complaint = require('./models/Complaint');
    const complaints = await Complaint.find();
    console.log(`Found ${complaints.length} complaints:`);
    complaints.forEach((c, i) => {
        const imgPreview = c.image ? (c.image.startsWith('http') ? 'URL' : 'BASE64 (len: ' + c.image.length + ')') : 'NULL';
        console.log(`${i+1}. "${c.title}" - Status: ${c.status}, Image: ${imgPreview}, Lat: ${c.location.latitude}, Lon: ${c.location.longitude}`);
    });
    process.exit(0);
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
}
checkDb();
