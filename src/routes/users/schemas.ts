import { Type, type Static } from "@sinclair/typebox";

export const UserSchema = Type.Object({
  id: Type.String({ format: "uuid" }),
  supabase_id: Type.String(),
  phone: Type.Union([Type.String(), Type.Null()]),
  display_name: Type.Union([Type.String(), Type.Null()]),
  avatar_url: Type.Union([Type.String(), Type.Null()]),
  created_at: Type.String(),
  updated_at: Type.String(),
});

export type User = Static<typeof UserSchema>;

export const UpdateUserBodySchema = Type.Object({
  display_name: Type.Optional(Type.String({ minLength: 1, maxLength: 100 })),
  avatar_url: Type.Optional(Type.Union([Type.String(), Type.Null()])),
});

export type UpdateUserBody = Static<typeof UpdateUserBodySchema>;
