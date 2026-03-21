const mongoose = require('mongoose');
require('dotenv').config();

async function fixDatabase() {
  try {
    console.log('Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/suchak');
    
    console.log('Dropping indices on Users collection...');
    const collections = await mongoose.connection.db.collections();
    const usersCollection = collections.find(c => c.collectionName === 'users');
    
    if (usersCollection) {
        try {
            await usersCollection.dropIndex('email_1');
            console.log('Successfully dropped legacy email_1 index!');
        } catch (e) {
            console.log('Index email_1 not found or already dropped.');
        }
    } else {
        console.log('Users collection not found.');
    }

    console.log('Database fix complete!');
    process.exit(0);
  } catch (error) {
    console.error('Error fixing database:', error);
    process.exit(1);
  }
}

fixDatabase();
