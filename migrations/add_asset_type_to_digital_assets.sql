-- Add asset_type column to digital_assets table to distinguish between digital and physical assets
-- Run this migration in your Supabase SQL editor

-- Add asset_type column (default to 'digital' for backward compatibility)
ALTER TABLE public.digital_assets 
ADD COLUMN IF NOT EXISTS asset_type text DEFAULT 'digital' CHECK (asset_type IN ('digital', 'physical'));

-- Update existing records to ensure they're marked as digital
UPDATE public.digital_assets 
SET asset_type = 'digital' 
WHERE asset_type IS NULL;

-- Set default to 'digital' for new records
ALTER TABLE public.digital_assets 
ALTER COLUMN asset_type SET DEFAULT 'digital';

-- Add comment for documentation
COMMENT ON COLUMN public.digital_assets.asset_type IS 'Type of asset: digital (online accounts, platforms) or physical (tangible assets like property, vehicles)';

-- Make beloved_id NOT NULL for physical assets (optional for digital)
-- Note: This is handled in application logic, but we keep the constraint flexible
-- Physical assets will require beloved_id in the application layer
