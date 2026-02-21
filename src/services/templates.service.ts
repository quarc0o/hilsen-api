import { type SupabaseClient } from "@supabase/supabase-js";

export async function getTemplates(
  supabase: SupabaseClient,
  options: { category?: string; limit?: number; offset?: number } = {},
) {
  const { category, limit = 20, offset = 0 } = options;

  let query = supabase
    .from("templates")
    .select("*")
    .eq("is_active", true)
    .order("created_at", { ascending: false })
    .range(offset, offset + limit - 1);

  if (category) {
    query = query.eq("category", category);
  }

  const { data, error } = await query;

  if (error) throw error;
  return data;
}

export async function getTemplateCategories(supabase: SupabaseClient) {
  const { data, error } = await supabase.from("templates").select("category").eq("is_active", true);

  if (error) throw error;

  const counts = (data ?? []).reduce(
    (acc: Record<string, number>, row: { category: string }) => {
      acc[row.category] = (acc[row.category] ?? 0) + 1;
      return acc;
    },
    {} as Record<string, number>,
  );

  return Object.entries(counts).map(([category, count]) => ({
    category,
    count,
  }));
}

export async function getTemplateBySlug(supabase: SupabaseClient, slug: string) {
  const { data, error } = await supabase
    .from("templates")
    .select("*")
    .eq("slug", slug)
    .eq("is_active", true)
    .single();

  if (error && error.code === "PGRST116") {
    return null;
  }

  if (error) throw error;
  return data;
}

export async function createTemplate(
  supabase: SupabaseClient,
  template: {
    slug: string;
    title: string;
    body_template: string;
    category: string;
    image_url?: string | null;
  },
) {
  const { data, error } = await supabase.from("templates").insert(template).select().single();

  if (error) throw error;
  return data;
}

export async function updateTemplate(
  supabase: SupabaseClient,
  id: string,
  updates: Partial<{
    slug: string;
    title: string;
    body_template: string;
    category: string;
    image_url: string | null;
    is_active: boolean;
  }>,
) {
  const { data, error } = await supabase
    .from("templates")
    .update(updates)
    .eq("id", id)
    .select()
    .single();

  if (error && error.code === "PGRST116") {
    return null;
  }

  if (error) throw error;
  return data;
}

export async function deleteTemplate(supabase: SupabaseClient, id: string) {
  const { error } = await supabase.from("templates").delete().eq("id", id);

  if (error) throw error;
}
