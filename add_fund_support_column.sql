-- Add fund_support_categories column to trust table
-- This stores an array of selected fund support categories (education, living, healthcare, charitable, debt)
-- 
-- IMPORTANT: This column is OPTIONAL and backward compatible:
-- - Uses IF NOT EXISTS to safely add column if it doesn't exist
-- - Defaults to empty array '{}' for existing records
-- - Column is nullable, so existing records won't break
-- - Safe to run on production database with existing data

ALTER TABLE public.trust 
ADD COLUMN IF NOT EXISTS fund_support_categories text[] DEFAULT '{}'::text[];

-- Add comment to document the column
COMMENT ON COLUMN public.trust.fund_support_categories IS 'Optional array of fund support categories selected by the user: education, living, healthcare, charitable, debt. Defaults to empty array for backward compatibility.';

-- Add fund support configurations column to trust table
-- This stores per-category configuration (duration and payment settings) as JSONB
-- Structure: { "categoryId": { "durationType": "age"|"lifetime", "endAge": number, "isRegularPayments": boolean, "paymentAmount": number, "paymentFrequency": "monthly"|"quarterly"|"yearly"|"when_conditions", "releaseCondition": "as_needed"|"lump_sum" } }
-- 
-- IMPORTANT: This column is OPTIONAL and backward compatible:
-- - Uses IF NOT EXISTS to safely add column if it doesn't exist
-- - Column is nullable, so existing records won't break
-- - Safe to run on production database with existing data

ALTER TABLE public.trust 
ADD COLUMN IF NOT EXISTS fund_support_configs jsonb DEFAULT '{}'::jsonb;

-- Add comment to document the column
COMMENT ON COLUMN public.trust.fund_support_configs IS 'Optional JSONB object storing per-category configuration for fund support. Each key is a category ID (education, living, healthcare, charitable, debt) with values containing duration and payment configuration. Nullable for backward compatibility.';

-- Create trust_executor junction table
-- This table stores the relationship between trusts and executors
-- Supports both "someone_i_know" (beloved IDs) and "sampul_professional" executors
-- 
-- IMPORTANT: This table is OPTIONAL and backward compatible:
-- - Uses IF NOT EXISTS to safely create table if it doesn't exist
-- - Safe to run on production database with existing data

`CREATE TABLE IF NOT EXISTS public.trust_executor (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  trust_id bigint NOT NULL,
  executor_type text NOT NULL CHECK (executor_type IN ('someone_i_know', 'sampul_professional')),
  beloved_id integer, -- NULL for sampul_professional, references beloved.id for someone_i_know
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT trust_executor_pkey PRIMARY KEY (id),
  CONSTRAINT trust_executor_trust_id_fkey FOREIGN KEY (trust_id) REFERENCES public.trust(id) ON DELETE CASCADE,
  CONSTRAINT trust_executor_beloved_id_fkey FOREIGN KEY (beloved_id) REFERENCES public.beloved(id) ON DELETE SET NULL,
  -- Ensure beloved_id is provided when executor_type is 'someone_i_know'
  CONSTRAINT trust_executor_beloved_check CHECK (
    (executor_type = 'someone_i_know' AND beloved_id IS NOT NULL) OR
    (executor_type = 'sampul_professional' AND beloved_id IS NULL)
  ),
  -- Prevent duplicate executor assignments for the same trust
  CONSTRAINT trust_executor_unique UNIQUE (trust_id, executor_type, beloved_id)
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS trust_executor_trust_id_idx ON public.trust_executor(trust_id);
CREATE INDEX IF NOT EXISTS trust_executor_beloved_id_idx ON public.trust_executor(beloved_id) WHERE beloved_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS trust_executor_type_idx ON public.trust_executor(executor_type);

-- Add comments to document the table
COMMENT ON TABLE public.trust_executor IS 'Junction table storing relationships between trusts and executors. Supports both family members/friends (someone_i_know) and Sampul professional executors.';
COMMENT ON COLUMN public.trust_executor.trust_id IS 'Reference to the trust';
COMMENT ON COLUMN public.trust_executor.executor_type IS 'Type of executor: "someone_i_know" for family member/friend, "sampul_professional" for Sampul professional executor';
COMMENT ON COLUMN public.trust_executor.beloved_id IS 'Reference to beloved (family member) when executor_type is "someone_i_know". NULL for sampul_professional.';

-- Enable Row Level Security (RLS)
ALTER TABLE public.trust_executor ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (for idempotency)
DROP POLICY IF EXISTS "Users can view executors for their own trusts" ON public.trust_executor;
DROP POLICY IF EXISTS "Users can create executors for their own trusts" ON public.trust_executor;
DROP POLICY IF EXISTS "Users can update executors for their own trusts" ON public.trust_executor;
DROP POLICY IF EXISTS "Users can delete executors for their own trusts" ON public.trust_executor;

-- Policy: Users can view executors for trusts they own
CREATE POLICY "Users can view executors for their own trusts"
ON public.trust_executor
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.trust
    WHERE trust.id = trust_executor.trust_id
    AND trust.uuid = auth.uid()
  )
);

-- Policy: Users can create executors for trusts they own
CREATE POLICY "Users can create executors for their own trusts"
ON public.trust_executor
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.trust
    WHERE trust.id = trust_executor.trust_id
    AND trust.uuid = auth.uid()
  )
);

-- Policy: Users can update executors for trusts they own
CREATE POLICY "Users can update executors for their own trusts"
ON public.trust_executor
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.trust
    WHERE trust.id = trust_executor.trust_id
    AND trust.uuid = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.trust
    WHERE trust.id = trust_executor.trust_id
    AND trust.uuid = auth.uid()
  )
);

-- Policy: Users can delete executors for trusts they own
CREATE POLICY "Users can delete executors for their own trusts"
ON public.trust_executor
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.trust
    WHERE trust.id = trust_executor.trust_id
    AND trust.uuid = auth.uid()
  )
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.trust_executor ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (for idempotency)
DROP POLICY IF EXISTS "Users can view executors for their own trusts" ON public.trust_executor;
DROP POLICY IF EXISTS "Users can create executors for their own trusts" ON public.trust_executor;
DROP POLICY IF EXISTS "Users can update executors for their own trusts" ON public.trust_executor;
DROP POLICY IF EXISTS "Users can delete executors for their own trusts" ON public.trust_executor;

-- Policy: Users can view executors for trusts they own
CREATE POLICY "Users can view executors for their own trusts"
ON public.trust_executor
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.trust
    WHERE trust.id = trust_executor.trust_id
    AND trust.uuid = auth.uid()
  )
);

-- Policy: Users can create executors for trusts they own
CREATE POLICY "Users can create executors for their own trusts"
ON public.trust_executor
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.trust
    WHERE trust.id = trust_executor.trust_id
    AND trust.uuid = auth.uid()
  )
);

-- Policy: Users can update executors for trusts they own
CREATE POLICY "Users can update executors for their own trusts"
ON public.trust_executor
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.trust
    WHERE trust.id = trust_executor.trust_id
    AND trust.uuid = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.trust
    WHERE trust.id = trust_executor.trust_id
    AND trust.uuid = auth.uid()
  )
);

-- Policy: Users can delete executors for trusts they own
CREATE POLICY "Users can delete executors for their own trusts"
ON public.trust_executor
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.trust
    WHERE trust.id = trust_executor.trust_id
    AND trust.uuid = auth.uid()
  )
);
