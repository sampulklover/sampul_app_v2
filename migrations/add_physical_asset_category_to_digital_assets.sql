-- Add physical_asset_category column so we can remember
-- which type of physical asset the user selected (land, vehicles, jewellery, etc.)
-- Run this migration in your Supabase SQL editor.

ALTER TABLE public.digital_assets
ADD COLUMN IF NOT EXISTS physical_asset_category text;

COMMENT ON COLUMN public.digital_assets.physical_asset_category IS
'For physical assets only: high-level category selected by user (land, houses_buildings, vehicles, jewellery, etc.)';

