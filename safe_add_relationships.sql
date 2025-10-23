-- Safe migration script: Add new relationship values to existing enum
-- This approach keeps all existing user data intact and just adds new values

-- Step 1: Add new relationship values to the existing relationships enum
-- These are the new waris relationships (entitled to inheritance under Islamic law)
ALTER TYPE relationships ADD VALUE 'father';
ALTER TYPE relationships ADD VALUE 'mother';
ALTER TYPE relationships ADD VALUE 'husband';
ALTER TYPE relationships ADD VALUE 'wife';
ALTER TYPE relationships ADD VALUE 'son';
ALTER TYPE relationships ADD VALUE 'daughter';

-- Step 2: Add new non-waris relationships
ALTER TYPE relationships ADD VALUE 'grandparent';
ALTER TYPE relationships ADD VALUE 'grandchild';
ALTER TYPE relationships ADD VALUE 'uncle';
ALTER TYPE relationships ADD VALUE 'aunt';
ALTER TYPE relationships ADD VALUE 'nephew';
ALTER TYPE relationships ADD VALUE 'niece';
ALTER TYPE relationships ADD VALUE 'cousin';

-- Step 3: Verify the new values were added successfully
-- Run this query to see all available relationship values:
-- SELECT unnest(enum_range(NULL::relationships)) as relationship_value;

-- Step 4: Check if any other tables use the relationships enum and need updating
-- For example, if trust_beneficiary table also uses relationships:
-- SELECT column_name, data_type 
-- FROM information_schema.columns 
-- WHERE table_name = 'trust_beneficiary' AND column_name = 'relationship';

-- Step 5: Test that existing data still works
-- SELECT relationship, COUNT(*) 
-- FROM beloved 
-- GROUP BY relationship 
-- ORDER BY relationship;
