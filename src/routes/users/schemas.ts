import { Type, type Static } from "@sinclair/typebox";

export const UserSchema = Type.Object({
  id: Type.String({ format: "uuid" }),
  supabase_id: Type.Union([Type.String(), Type.Null()]),
  phone_number: Type.Union([Type.String(), Type.Null()]),
  email: Type.Union([Type.String(), Type.Null()]),
  first_name: Type.Union([Type.String(), Type.Null()]),
  last_name: Type.Union([Type.String(), Type.Null()]),
  created_at: Type.String(),
});

export type User = Static<typeof UserSchema>;

export const UpdateUserBodySchema = Type.Object({
  first_name: Type.Optional(Type.String({ minLength: 1, maxLength: 100 })),
  last_name: Type.Optional(Type.String({ minLength: 1, maxLength: 100 })),
  email: Type.Optional(Type.Union([Type.String({ format: "email" }), Type.Null()])),
});

export type UpdateUserBody = Static<typeof UpdateUserBodySchema>;
