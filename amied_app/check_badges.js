import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config({ path: 'c:/Proyectos/AMIED/amied_app/.env' });

const supabaseUrl = 'https://ebzjvrtfdqlscltbnlib.supabase.co';
const supabaseKey = process.env.SUPABASE_ANON_KEY;
if (!supabaseKey) throw new Error("No anon key");

const supabase = createClient(supabaseUrl, supabaseKey);

async function run() {
  const { data: badges } = await supabase.from('badges').select('*');
  console.log("All badges:");
  console.log(JSON.stringify(badges, null, 2));
}

run().catch(console.error);
