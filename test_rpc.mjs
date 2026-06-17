import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://ebzjvrtfdqlscltbnlib.supabase.co'
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImViemp2cnRmZHFsc2NsdGJubGliIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEzOTc3MTksImV4cCI6MjA5Njk3MzcxOX0.WbEppGR1nbm0O8wfTd3nf--Th8yMrnuqzYPfB3RisaA'

const supabase = createClient(supabaseUrl, supabaseKey)

async function test() {
  const { data, error } = await supabase
    .from('pg_proc')
    .select('*')
    .eq('proname', 'get_all_users_progress');
  
  if (error) {
    console.error(error);
  } else {
    console.log(JSON.stringify(data, null, 2));
  }
}

test();
