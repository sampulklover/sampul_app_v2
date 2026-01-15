-- Add is_custom flag to digital_assets table to differentiate custom/manual assets from Brandfetch assets
-- Run this migration in your Supabase SQL editor

ALTER TABLE public.digital_assets 
ADD COLUMN IF NOT EXISTS is_custom boolean DEFAULT false;

-- Update existing records: if logo_url is null, mark as custom (backfill)
UPDATE public.digital_assets 
SET is_custom = true 
WHERE new_service_platform_logo_url IS NULL 
  AND is_custom IS NULL;

-- Set default to false for new records
ALTER TABLE public.digital_assets 
ALTER COLUMN is_custom SET DEFAULT false;

-- Add comment for documentation
COMMENT ON COLUMN public.digital_assets.is_custom IS 'Indicates if asset was manually added by user (true) or found via Brandfetch API (false)';

