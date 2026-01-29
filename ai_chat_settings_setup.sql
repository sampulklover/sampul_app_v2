-- AI Chat Settings Table
-- Allows admins to manage AI chat configuration for better user experience

CREATE TABLE IF NOT EXISTS public.ai_chat_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  system_prompt TEXT NOT NULL DEFAULT 'You are Sampul AI, a helpful assistant for estate planning and will management. You help users with questions about creating wills, managing assets, family planning, and estate planning. Be friendly, professional, and knowledgeable about these topics. Keep answers concise (2–4 short sentences). Use bullet points only when listing items. Avoid long paragraphs.',
  max_tokens INTEGER NOT NULL DEFAULT 220,
  temperature NUMERIC(3, 2) NOT NULL DEFAULT 0.5,
  model TEXT,
  welcome_message TEXT NOT NULL DEFAULT 'Hello! I''m Sampul AI, your estate planning assistant. How can I help you today?',
  -- Resource management fields (common practice for AI management)
  resources JSONB DEFAULT '[]'::jsonb, -- Array of {url, title, description, type} - unified knowledge base
  context_resources TEXT, -- Additional context text for AI to reference
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_by UUID REFERENCES auth.users(id)
);

-- Create index for active settings lookup
CREATE INDEX IF NOT EXISTS idx_ai_chat_settings_active ON public.ai_chat_settings(is_active) WHERE is_active = true;

-- Add new columns if they don't exist (for existing tables)
DO $$ 
BEGIN
  -- Add resources column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'ai_chat_settings' 
    AND column_name = 'resources'
  ) THEN
    ALTER TABLE public.ai_chat_settings ADD COLUMN resources JSONB DEFAULT '[]'::jsonb;
  END IF;

  -- Add context_resources column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'ai_chat_settings' 
    AND column_name = 'context_resources'
  ) THEN
    ALTER TABLE public.ai_chat_settings ADD COLUMN context_resources TEXT;
  END IF;
END $$;

-- Enable Row Level Security
ALTER TABLE public.ai_chat_settings ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (for idempotency)
DROP POLICY IF EXISTS "Anyone can read active AI chat settings" ON public.ai_chat_settings;
DROP POLICY IF EXISTS "Admins can read all AI chat settings" ON public.ai_chat_settings;
DROP POLICY IF EXISTS "Admins can insert AI chat settings" ON public.ai_chat_settings;
DROP POLICY IF EXISTS "Admins can update AI chat settings" ON public.ai_chat_settings;
DROP POLICY IF EXISTS "Admins can delete AI chat settings" ON public.ai_chat_settings;

-- Policy: Anyone can read active settings (for app usage)
CREATE POLICY "Anyone can read active AI chat settings"
ON public.ai_chat_settings
FOR SELECT
USING (is_active = true);

-- Policy: Only admins can read all settings (including inactive)
CREATE POLICY "Admins can read all AI chat settings"
ON public.ai_chat_settings
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.roles
    WHERE roles.uuid = auth.uid()
    AND roles.role = 'admin'
  )
);

-- Policy: Only admins can insert settings
CREATE POLICY "Admins can insert AI chat settings"
ON public.ai_chat_settings
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.roles
    WHERE roles.uuid = auth.uid()
    AND roles.role = 'admin'
  )
);

-- Policy: Only admins can update settings
CREATE POLICY "Admins can update AI chat settings"
ON public.ai_chat_settings
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.roles
    WHERE roles.uuid = auth.uid()
    AND roles.role = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.roles
    WHERE roles.uuid = auth.uid()
    AND roles.role = 'admin'
  )
);

-- Policy: Only admins can delete settings
CREATE POLICY "Admins can delete AI chat settings"
ON public.ai_chat_settings
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.roles
    WHERE roles.uuid = auth.uid()
    AND roles.role = 'admin'
  )
);

-- Insert default active settings (only if no active settings exist)
INSERT INTO public.ai_chat_settings (
  system_prompt,
  max_tokens,
  temperature,
  welcome_message,
  resources,
  context_resources,
  is_active
) 
SELECT 
  'You are Sampul AI, a helpful assistant for estate planning and will management. You help users with questions about creating wills, managing assets, family planning, and estate planning. Be friendly, professional, and knowledgeable about these topics. Keep answers concise (2–4 short sentences). Use bullet points only when listing items. Avoid long paragraphs.',
  220,
  0.5,
  'Hello! I''m Sampul AI, your estate planning assistant. How can I help you today?',
  '[]'::jsonb,
  NULL,
  true
WHERE NOT EXISTS (
  SELECT 1 FROM public.ai_chat_settings WHERE is_active = true
);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_ai_chat_settings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  NEW.updated_by = auth.uid();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger if exists (for idempotency)
DROP TRIGGER IF EXISTS update_ai_chat_settings_timestamp ON public.ai_chat_settings;

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_ai_chat_settings_timestamp
BEFORE UPDATE ON public.ai_chat_settings
FOR EACH ROW
EXECUTE FUNCTION update_ai_chat_settings_updated_at();
