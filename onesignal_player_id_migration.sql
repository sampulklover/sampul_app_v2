-- OneSignal Player ID Migration
-- This migration adds a column to store OneSignal player IDs in the accounts table
-- Run this migration in your Supabase SQL editor

-- Add onesignal_player_id column to accounts table
ALTER TABLE accounts 
ADD COLUMN IF NOT EXISTS onesignal_player_id TEXT;

-- Add index for faster lookups (optional but recommended)
CREATE INDEX IF NOT EXISTS idx_accounts_onesignal_player_id 
ON accounts(onesignal_player_id);

-- Add comment to document the column
COMMENT ON COLUMN accounts.onesignal_player_id IS 'OneSignal player ID (device token) for push notifications';
