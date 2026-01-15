-- Row Level Security (RLS) Policies for verification table
-- Allows users to manage their own verification records

-- Enable Row Level Security
ALTER TABLE public.verification ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (for idempotency)
DROP POLICY IF EXISTS "Users can view their own verifications" ON public.verification;
DROP POLICY IF EXISTS "Users can create their own verifications" ON public.verification;
DROP POLICY IF EXISTS "Users can update their own verifications" ON public.verification;
DROP POLICY IF EXISTS "Authenticated users can manage their verifications" ON public.verification;

-- Policy: Users can view their own verification records
CREATE POLICY "Users can view their own verifications"
ON public.verification
FOR SELECT
USING (auth.uid() = uuid);

-- Policy: Users can create verification records for themselves
CREATE POLICY "Users can create their own verifications"
ON public.verification
FOR INSERT
WITH CHECK (auth.uid() = uuid);

-- Policy: Users can update their own verification records
CREATE POLICY "Users can update their own verifications"
ON public.verification
FOR UPDATE
USING (auth.uid() = uuid)
WITH CHECK (auth.uid() = uuid);

-- Alternative: Single policy for all operations (simpler, same security)
-- Uncomment this and comment out the above if you prefer a single policy
-- CREATE POLICY "Authenticated users can manage their verifications"
-- ON public.verification
-- FOR ALL
-- USING (auth.uid() = uuid)
-- WITH CHECK (auth.uid() = uuid);

