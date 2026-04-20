const COLLECTION = "Card_Templates";

interface DirectusTemplate {
  id: string;
  status: string;
  Template_Data: unknown;
  Template_Preview: string;
}

export interface Template {
  id: string;
  data: unknown;
  preview_url: string;
}

function mapTemplate(directusUrl: string, item: DirectusTemplate): Template {
  return {
    id: item.id,
    data: item.Template_Data,
    preview_url: `${directusUrl}/assets/${item.Template_Preview}`,
  };
}

export async function getTemplates(directusUrl: string) {
  const params = new URLSearchParams({
    "filter[status][_eq]": "published",
    limit: "-1",
  });

  const res = await fetch(`${directusUrl}/items/${COLLECTION}?${params}`);
  if (!res.ok) {
    throw new Error(`Directus error: ${res.status} ${res.statusText}`);
  }

  const { data } = (await res.json()) as { data: DirectusTemplate[] };
  return (data ?? []).map((item) => mapTemplate(directusUrl, item));
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
  if (data.status !== "published") {
    return null;
  }
  return mapTemplate(directusUrl, data);
}
