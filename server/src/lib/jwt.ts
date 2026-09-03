import jwt from "jsonwebtoken";

export type UserRole =
  | "ADMIN"
  | "EXECUTIVE"
  | "WAREHOUSE_MANAGER"
  | "SALES_REP"
  | "PHARMACIST";

export type AuthTokenPayload = {
  userId: number;
  username: string;
  role: UserRole;
};

function getJwtSecret(): string {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    throw new Error("JWT_SECRET is not set");
  }
  return secret;
}

export function signAuthToken(payload: AuthTokenPayload): string {
  const expiresIn = process.env.JWT_EXPIRES_IN || "1d";

  return jwt.sign(
    {
      userId: payload.userId,
      username: payload.username,
      role: payload.role,
    },
    getJwtSecret(),
    { expiresIn: expiresIn as jwt.SignOptions["expiresIn"] },
  );
}

export function verifyAuthToken(token: string): AuthTokenPayload {
  const decoded = jwt.verify(token, getJwtSecret());

  if (typeof decoded !== "object" || decoded === null) {
    throw new Error("Invalid auth token");
  }

  const { userId, username, role } = decoded as AuthTokenPayload;

  if (
    typeof userId !== "number" ||
    typeof username !== "string" ||
    typeof role !== "string"
  ) {
    throw new Error("Invalid auth token payload");
  }

  return { userId, username, role };
}
