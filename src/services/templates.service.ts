const COLLECTION = "Greeting_Cards";

interface DirectusTemplate {
  id: string;
  card_title: string;
  categories: string[];
  image_url: string;
}

export interface Template {
  id: string;
  card_title: string;
  categories: string[];
  image_url: string;
}

function mapTemplate(directusUrl: string, item: DirectusTemplate): Template {
  return {
    id: item.id,
    card_title: item.card_title,
    categories: item.categories ?? [],
    image_url: `${directusUrl}/assets/${item.image_url}`,
  };
}

export async function getTemplates(
  directusUrl: string,
  options: {
    category?: string;
    search?: string;
    limit?: number;
    offset?: number;
  } = {},
) {
  const { category, search, limit = 20, offset = 0 } = options;

  const params = new URLSearchParams({
    limit: String(limit),
    offset: String(offset),
  });

  if (category) {
    params.set("filter[categories][_contains]", category);
  }

  if (search) {
    params.set("filter[card_title][_icontains]", search);
  }

  const res = await fetch(`${directusUrl}/items/${COLLECTION}?${params}`);
  if (!res.ok) {
    throw new Error(`Directus error: ${res.status} ${res.statusText}`);
  }

  const { data } = (await res.json()) as { data: DirectusTemplate[] };
  return (data ?? []).map((item) => mapTemplate(directusUrl, item));
}

export async function getTemplateCategories(directusUrl: string) {
  const params = new URLSearchParams({
    "fields[]": "categories",
    limit: "-1",
  });

  const res = await fetch(`${directusUrl}/items/${COLLECTION}?${params}`);
  if (!res.ok) {
    throw new Error(`Directus error: ${res.status} ${res.statusText}`);
  }

  const { data } = (await res.json()) as { data: Pick<DirectusTemplate, "categories">[] };

  const counts: Record<string, number> = {};
  for (const item of data ?? []) {
    for (const cat of item.categories ?? []) {
      counts[cat] = (counts[cat] ?? 0) + 1;
    }
  }

  return Object.entries(counts).map(([category, count]) => ({ category, count }));
}

export async function getTemplateById(directusUrl: string, id: string) {
  const res = await fetch(`${directusUrl}/items/${COLLECTION}/${id}`);

  if (res.status === 403 || res.status === 404) {
    return null;
  }

  if (!res.ok) {
    throw new Error(`Directus error: ${res.status} ${res.statusText}`);
  }

  const { data } = (await res.json()) as { data: DirectusTemplate };
  return mapTemplate(directusUrl, data);
}
