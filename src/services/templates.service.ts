import { type SupabaseClient } from "@supabase/supabase-js";

export async function getTemplates(
  supabase: SupabaseClient,
  options: {
    category?: string;
    tags?: string;
    search?: string;
    limit?: number;
    offset?: number;
  } = {},
) {
  const { category, tags, search, limit = 20, offset = 0 } = options;

  let query = supabase
    .from("card_templates")
    .select("*")
    .eq("is_published", true)
    .order("sort_order", { ascending: true })
    .order("created_at", { ascending: false })
    .range(offset, offset + limit - 1);

  if (category) {
    query = query.eq("category", category);
  }

  if (tags) {
    query = query.contains("tags", [tags]);
  }

  if (search) {
    query = query.or(`title.ilike.%${search}%,description.ilike.%${search}%`);
  }

  const { data, error } = await query;

  if (error) throw error;
  return data;
}

export async function getTemplateCategories(supabase: SupabaseClient) {
  const { data, error } = await supabase
    .from("card_templates")
    .select("category")
    .eq("is_published", true);

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
    .from("card_templates")
    .select("*")
    .eq("slug", slug)
    .eq("is_published", true)
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
    category: string;
    image_url: string;
    subtitle?: string | null;
    description?: string | null;
    tags?: string[];
    is_premium?: boolean;
    sort_order?: number;
  },
) {
  const { data, error } = await supabase.from("card_templates").insert(template).select().single();

  if (error) throw error;
  return data;
}

export async function updateTemplate(
  supabase: SupabaseClient,
  id: string,
  updates: Partial<{
    slug: string;
    title: string;
    subtitle: string | null;
    description: string | null;
    category: string;
    tags: string[];
    image_url: string;
    is_premium: boolean;
    is_published: boolean;
    sort_order: number;
  }>,
) {
  const { data, error } = await supabase
    .from("card_templates")
    .update({ ...updates, updated_at: new Date().toISOString() })
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
  const { error } = await supabase.from("card_templates").delete().eq("id", id);

  if (error) throw error;
}
