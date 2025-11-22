import Link from 'next/link';
import { Restaurant } from '@/lib/api';

interface RestaurantCardProps {
  restaurant: Restaurant;
}

/**
 * RestaurantCard component
 * Displays a single restaurant in a card format
 */
export default function RestaurantCard({ restaurant }: RestaurantCardProps) {
  return (
    <Link
      href={`/admin/restaurants/${restaurant.id}`}
      className="block bg-white rounded-lg shadow hover:shadow-lg transition-shadow p-6"
    >
      <div className="flex justify-between items-start">
        <div className="flex-1">
          <h3 className="text-xl font-semibold text-gray-900 mb-2">
            {restaurant.name}
          </h3>
          
          {restaurant.description && (
            <p className="text-gray-600 mb-3 line-clamp-2">
              {restaurant.description}
            </p>
          )}
          
          <div className="space-y-1 text-sm text-gray-500">
            {restaurant.address && (
              <p className="flex items-center gap-2">
                <span>📍</span>
                {restaurant.address}
              </p>
            )}
            {restaurant.phone && (
              <p className="flex items-center gap-2">
                <span>📞</span>
                {restaurant.phone}
              </p>
            )}
            {restaurant.email && (
              <p className="flex items-center gap-2">
                <span>✉️</span>
                {restaurant.email}
              </p>
            )}
          </div>

          {(restaurant.website || restaurant.instagram) && (
            <div className="mt-3 flex gap-3">
              {restaurant.website && (
                <a
                  href={restaurant.website}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-blue-600 hover:text-blue-800 text-sm"
                  onClick={(e) => e.stopPropagation()}
                >
                  🌐 Website
                </a>
              )}
              {restaurant.instagram && (
                <a
                  href={`https://instagram.com/${restaurant.instagram.replace('@', '')}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-pink-600 hover:text-pink-800 text-sm"
                  onClick={(e) => e.stopPropagation()}
                >
                  📷 Instagram
                </a>
              )}
            </div>
          )}
        </div>

        <div className="ml-4">
          <span className="text-gray-400 text-2xl">→</span>
        </div>
      </div>
    </Link>
  );
}
