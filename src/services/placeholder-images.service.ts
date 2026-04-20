const COLLECTION = "Placeholder_Images";

interface DirectusPlaceholderImage {
  id: string;
  Image: string;
}

export interface PlaceholderImage {
  id: string;
  image_url: string;
}

function mapPlaceholderImage(
  directusUrl: string,
  item: DirectusPlaceholderImage,
): PlaceholderImage {
  return {
    id: item.id,
    image_url: `${directusUrl}/assets/${item.Image}`,
  };
}

export type FileUpload = { buffer: Buffer; filename: string; mimetype: string };

export async function uploadFileToDirectus(
  directusUrl: string,
  token: string,
  file: FileUpload,
): Promise<string> {
  const arrayBuffer = file.buffer.buffer.slice(
    file.buffer.byteOffset,
    file.buffer.byteOffset + file.buffer.byteLength,
  ) as ArrayBuffer;
  const formData = new FormData();
  formData.append("file", new Blob([arrayBuffer], { type: file.mimetype }), file.filename);

  const res = await fetch(`${directusUrl}/files`, {
    method: "POST",
    headers: { Authorization: `Bearer ${token}` },
    body: formData,
  });
  if (!res.ok) {
    throw new Error(`Directus file upload error: ${res.status} ${res.statusText}`);
  }
  const { data } = (await res.json()) as { data: { id: string } };
  return data.id;
}

export async function uploadPlaceholderImage(
  directusUrl: string,
  token: string,
  file: FileUpload,
): Promise<PlaceholderImage> {
  const fileId = await uploadFileToDirectus(directusUrl, token, file);

  const itemRes = await fetch(`${directusUrl}/items/${COLLECTION}`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ Image: fileId }),
  });
  if (!itemRes.ok) {
    throw new Error(`Directus item create error: ${itemRes.status} ${itemRes.statusText}`);
  }
  const { data: item } = (await itemRes.json()) as { data: DirectusPlaceholderImage };
  return mapPlaceholderImage(directusUrl, item);
}

export async function getPlaceholderImages(directusUrl: string) {
  const res = await fetch(`${directusUrl}/items/${COLLECTION}?limit=-1`);
  if (!res.ok) {
    throw new Error(`Directus error: ${res.status} ${res.statusText}`);
  }

  const { data } = (await res.json()) as { data: DirectusPlaceholderImage[] };
  return (data ?? []).map((item) => mapPlaceholderImage(directusUrl, item));
}
