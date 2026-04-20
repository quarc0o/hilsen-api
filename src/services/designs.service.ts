const COLLECTION = "Greeting_Cards";

interface DirectusDesign {
  id: string;
  card_title: string;
  categories: string[];
  image_url: string;
}

export interface Design {
  id: string;
  card_title: string;
  categories: string[];
  image_url: string;
}

function mapDesign(directusUrl: string, item: DirectusDesign): Design {
  return {
    id: item.id,
    card_title: item.card_title,
    categories: item.categories ?? [],
    image_url: `${directusUrl}/assets/${item.image_url}`,
  };
}

export async function getDesigns(
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

  const { data } = (await res.json()) as { data: DirectusDesign[] };
  return (data ?? []).map((item) => mapDesign(directusUrl, item));
}

export async function getDesignCategories(directusUrl: string) {
  const params = new URLSearchParams({
    "fields[]": "categories",
    limit: "-1",
  });

  const res = await fetch(`${directusUrl}/items/${COLLECTION}?${params}`);
  if (!res.ok) {
    throw new Error(`Directus error: ${res.status} ${res.statusText}`);
  }

  const { data } = (await res.json()) as { data: Pick<DirectusDesign, "categories">[] };

  const counts: Record<string, number> = {};
  for (const item of data ?? []) {
    for (const cat of item.categories ?? []) {
      counts[cat] = (counts[cat] ?? 0) + 1;
    }
  }

  return Object.entries(counts).map(([category, count]) => ({ category, count }));
}

export async function getDesignsByIds(directusUrl: string, ids: string[]) {
  if (ids.length === 0) return new Map<string, Design>();

  const params = new URLSearchParams({
    "filter[id][_in]": ids.join(","),
    limit: "-1",
  });

  const res = await fetch(`${directusUrl}/items/${COLLECTION}?${params}`);
  if (!res.ok) {
    throw new Error(`Directus error: ${res.status} ${res.statusText}`);
  }

  const { data } = (await res.json()) as { data: DirectusDesign[] };
  const map = new Map<string, Design>();
  for (const item of data ?? []) {
    map.set(item.id, mapDesign(directusUrl, item));
  }
  return map;
}

export async function getDesignById(directusUrl: string, id: string) {
  const res = await fetch(`${directusUrl}/items/${COLLECTION}/${id}`);

  if (res.status === 403 || res.status === 404) {
    return null;
  }

  if (!res.ok) {
    throw new Error(`Directus error: ${res.status} ${res.statusText}`);
  }

  const { data } = (await res.json()) as { data: DirectusDesign };
  return mapDesign(directusUrl, data);
}
