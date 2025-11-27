'use client';

import { useState, useMemo } from 'react';
import RestaurantCard from './RestaurantCard';
import { Restaurant } from '@/lib/api';

interface RestaurantListProps {
  restaurants: Restaurant[];
}

/**
 * RestaurantList component
 * Displays a paginated and searchable list of restaurants
 */
export default function RestaurantList({ restaurants }: RestaurantListProps) {
  const [searchTerm, setSearchTerm] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 10;

  // Filter restaurants based on search term
  const filteredRestaurants = useMemo(() => {
    if (!searchTerm) return restaurants;
    
    const term = searchTerm.toLowerCase();
    return restaurants.filter((restaurant) =>
      restaurant.name.toLowerCase().includes(term) ||
      restaurant.address?.toLowerCase().includes(term) ||
      restaurant.description?.toLowerCase().includes(term)
    );
  }, [restaurants, searchTerm]);

  // Calculate pagination
  const totalPages = Math.ceil(filteredRestaurants.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const currentRestaurants = filteredRestaurants.slice(startIndex, endIndex);

  // Reset to page 1 when search term changes
  const handleSearch = (value: string) => {
    setSearchTerm(value);
    setCurrentPage(1);
  };

  return (
    <div className="space-y-6">
      {/* Search Bar */}
      <div className="bg-white rounded-lg shadow p-4">
        <input
          type="text"
          placeholder="Search restaurants by name, address, or description..."
          value={searchTerm}
          onChange={(e) => handleSearch(e.target.value)}
          className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </div>

      {/* Results Summary */}
      <div className="flex justify-between items-center text-sm text-gray-600">
        <p>
          Showing {currentRestaurants.length > 0 ? startIndex + 1 : 0} to{' '}
          {Math.min(endIndex, filteredRestaurants.length)} of{' '}
          {filteredRestaurants.length} restaurants
          {searchTerm && ' (filtered)'}
        </p>
      </div>

      {/* Restaurant Cards */}
      {currentRestaurants.length > 0 ? (
        <div className="grid gap-6 md:grid-cols-2">
          {currentRestaurants.map((restaurant) => (
            <RestaurantCard key={restaurant.id} restaurant={restaurant} />
          ))}
        </div>
      ) : (
        <div className="bg-white rounded-lg shadow p-12 text-center">
          <p className="text-gray-500 text-lg">
            {searchTerm
              ? 'No restaurants found matching your search.'
              : 'No restaurants available.'}
          </p>
        </div>
      )}

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex justify-center gap-2 mt-8">
          <button
            onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
            disabled={currentPage === 1}
            className="px-4 py-2 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Previous
          </button>
          
          <div className="flex items-center gap-2">
            {Array.from({ length: totalPages }, (_, i) => i + 1).map((page) => (
              <button
                key={page}
                onClick={() => setCurrentPage(page)}
                className={`px-4 py-2 rounded-lg ${
                  currentPage === page
                    ? 'bg-blue-600 text-white'
                    : 'bg-white border border-gray-300 hover:bg-gray-50'
                }`}
              >
                {page}
              </button>
            ))}
          </div>

          <button
            onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
            disabled={currentPage === totalPages}
            className="px-4 py-2 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Next
          </button>
        </div>
      )}
    </div>
  );
}
