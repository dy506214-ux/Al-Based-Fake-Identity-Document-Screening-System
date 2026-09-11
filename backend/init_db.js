const db = require('./db');

const initDatabase = async () => {
  try {
    console.log('Connecting to database to initialize tables...');

    // Create Users table
    await db.query(`
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(255) NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        role VARCHAR(50) DEFAULT 'OFFICER',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Create Documents table
    await db.query(`
      CREATE TABLE IF NOT EXISTS documents (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        document_type VARCHAR(50) NOT NULL,
        status VARCHAR(50) DEFAULT 'UPLOADED',
        review_decision VARCHAR(50) DEFAULT 'PENDING',
        file_data BYTEA,
        file_content_type VARCHAR(100),
        selfie_data BYTEA,
        selfie_content_type VARCHAR(100),
        uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);

    console.log('Database tables created successfully!');
  } catch (error) {
    console.error('Error creating database tables:', error);
  } finally {
    process.exit();
  }
};

initDatabase();
