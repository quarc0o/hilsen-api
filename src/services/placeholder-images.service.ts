const COLLECTION = "Placeholder_Images";

interface DirectusPlaceholderImage {
  id: string;
  Image: string;
}

export interface PlaceholderImage {
  id: string;
  image_url: string;
}

function mapPlaceholderImage(directusUrl: string, item: DirectusPlaceholderImage): PlaceholderImage {
  return {
    id: item.id,
    image_url: `${directusUrl}/assets/${item.Image}`,
  };
}

export async function getPlaceholderImages(directusUrl: string) {
  const res = await fetch(`${directusUrl}/items/${COLLECTION}?limit=-1`);
  if (!res.ok) {
    throw new Error(`Directus error: ${res.status} ${res.statusText}`);
  }

  const { data } = (await res.json()) as { data: DirectusPlaceholderImage[] };
  return (data ?? []).map((item) => mapPlaceholderImage(directusUrl, item));
}
