const COLLECTION = "Stickers";

interface DirectusSticker {
  id: string;
  image: string;
}

export interface Sticker {
  id: string;
  image_url: string;
}

function mapSticker(directusUrl: string, item: DirectusSticker): Sticker {
  return {
    id: item.id,
    image_url: `${directusUrl}/assets/${item.image}`,
  };
}

export async function getStickers(directusUrl: string) {
  const res = await fetch(`${directusUrl}/items/${COLLECTION}?limit=-1`);
  if (!res.ok) {
    throw new Error(`Directus error: ${res.status} ${res.statusText}`);
  }

  const { data } = (await res.json()) as { data: DirectusSticker[] };
  return (data ?? []).map((item) => mapSticker(directusUrl, item));
}

export async function getStickerById(directusUrl: string, id: string) {
  const res = await fetch(`${directusUrl}/items/${COLLECTION}/${id}`);

  if (res.status === 403 || res.status === 404) {
    return null;
  }

  if (!res.ok) {
    throw new Error(`Directus error: ${res.status} ${res.statusText}`);
  }

  const { data } = (await res.json()) as { data: DirectusSticker };
  return mapSticker(directusUrl, data);
}
