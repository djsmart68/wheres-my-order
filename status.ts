const ORDER_NUMBER_PATTERN = /^\d{6,10}$/;

const STATUSES = ["Processing", "Shipped", "Out for Delivery", "Delivered", "Delayed"];

export function isValidOrderNumber(orderNumber: string): boolean {
  return ORDER_NUMBER_PATTERN.test(orderNumber);
}

function hashDigits(orderNumber: string): number {
  let hash = 0;
  for (const char of orderNumber) {
    hash = (hash * 31 + char.charCodeAt(0)) >>> 0;
  }
  return hash;
}

export type OrderStatus = {
  orderNumber: string;
  status: string;
  estimatedDelivery: string;
};

export function getOrderStatus(orderNumber: string): OrderStatus {
  const hash = hashDigits(orderNumber);
  const status = STATUSES[hash % STATUSES.length];
  const daysOffset = hash % 10;

  const estimatedDelivery = new Date();
  estimatedDelivery.setDate(estimatedDelivery.getDate() + daysOffset);

  return {
    orderNumber,
    status,
    estimatedDelivery: estimatedDelivery.toISOString().slice(0, 10),
  };
}
