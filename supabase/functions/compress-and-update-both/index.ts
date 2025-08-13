import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';
import JSZip from 'https://esm.sh/jszip@3.10.1';
const BUCKET_NAME = 'compreesed.files';
const ZIP_PATH = 'ahadith_alzakah_data/ahadith_zakah.zip';
const VERSION_PATH = 'ahadith_alzakah_data/version.json';
async function getAuthenticatedUser(req: Request) {
  const supabaseClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? '' 
  );
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    throw new Error('Missing Authorization header. User is not authenticated.');
  }
  const jwt = authHeader.replace('Bearer ', '');
  const { data: { user }, error } = await supabaseClient.auth.getUser(jwt);
  if (error) {
    throw new Error(`Authentication error: ${error.message}`);
  }
  if (!user) {
    throw new Error('User not found or invalid token.');
  }
  return user;
}

serve(async (req: Request) => {
  try {
    await getAuthenticatedUser(req);
    console.log('User successfully authenticated.');
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SERVICE_KEY') ?? ''
    );

    const jsonData = await req.json();
    const jsonString = JSON.stringify(jsonData);
    console.log(`Compressing and uploading new data to bucket: ${BUCKET_NAME}`);
    const zip = new JSZip();
    zip.file("ahadith_zakah.json", new TextEncoder().encode(jsonString));
    const compressedBlob = await zip.generateAsync({
      type: "blob",
      compression: "DEFLATE",
      compressionOptions: {
        level: 9
      }
    });
    
    const { error: zipError } = await supabaseAdmin.storage
      .from(BUCKET_NAME)
      .upload(ZIP_PATH, compressedBlob, {
        upsert: true,
        contentType: 'application/zip'
      });
    if (zipError) throw new Error(`Failed to upload new ZIP: ${zipError.message}`);
    console.log('ZIP file uploaded successfully.');

    console.log('Updating version file...');
    const versionData = { version: jsonData.version };
    const versionString = JSON.stringify(versionData);
    
    const { error: versionError } = await supabaseAdmin.storage
      .from(BUCKET_NAME)
      .upload(VERSION_PATH, versionString, {
        upsert: true,
        contentType: 'application/json;charset=UTF-8'
      });
    if (versionError) throw new Error(`Failed to upload version file: ${versionError.message}`);
    console.log('Version file updated successfully.');

    return new Response(JSON.stringify({
      message: "All files updated successfully"
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });

  } catch (error) {
    console.error(error);
  
    if (error.message.includes('Authentication') || error.message.includes('User not found')) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 401, 
        headers: { 'Content-Type': 'application/json' },
      });
    }
    return new Response(JSON.stringify({
      error: error.message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});