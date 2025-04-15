import '@src/Popup.css';
import { useStorage, withErrorBoundary, withSuspense } from '@extension/shared';
import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';

const Popup = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  // House animation variants
  const houseVariants = {
    hover: {
      y: [0, -10, 0],
      transition: {
        duration: 2,
        repeat: Infinity,
        ease: "easeInOut"
      }
    }
  };

  // Logo animation variants
  const logoVariants = {
    initial: { scale: 0.8, opacity: 0 },
    animate: { 
      scale: 1, 
      opacity: 1,
      transition: { duration: 0.5 }
    }
  };

  interface SignInEvent extends React.FormEvent<HTMLFormElement> {}

  const handleSignIn = (e: SignInEvent): void => {
    e.preventDefault();
    setIsLoading(true);
    
    // Simulate authentication
    setTimeout(() => {
      setIsLoading(false);
      // In a real implementation, you would handle authentication here
      console.log('Sign in with:', email, password);
    }, 1500);
  };

  return (
    <div className="w-[360px] h-[480px] bg-white dark:bg-gray-800 text-gray-800 dark:text-white overflow-hidden">
      {/* Header should be 1/4 of pop height */}
      <div className="bg-primary-purple dark:bg-primary-purple/80 h-15 p-4 text-white text-center relative overflow-hidden">
        <div className="absolute inset-0 opacity-10">
          <div className="absolute top-0 left-0 w-full h-full bg-[url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDAlIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPjxwYXR0ZXJuIGlkPSJwYXR0ZXJuIiB4PSIwIiB5PSIwIiB3aWR0aD0iMjAiIGhlaWdodD0iMjAiIHBhdHRlcm5Vbml0cz0idXNlclNwYWNlT25Vc2UiIHBhdHRlcm5UcmFuc2Zvcm09InJvdGF0ZSg0NSkiPjxyZWN0IGlkPSJwYXR0ZXJuLWJnIiB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDAlIiBmaWxsPSJ0cmFuc3BhcmVudCI+PC9yZWN0PjxwYXRoIGZpbGw9IiNmZmZmZmYiIGQ9Ik0tMTAgLTEwaDIwdjIwaC0yMHoiPjwvcGF0aD48L3BhdHRlcm4+PHJlY3QgZmlsbD0idXJsKCNwYXR0ZXJuKSIgaGVpZ2h0PSIxMDAlIiB3aWR0aD0iMTAwJSI+PC9yZWN0Pjwvc3ZnPg==')]"></div>
        </div>
        
        <motion.div
          variants={logoVariants}
          initial="initial"
          animate="animate"
          className="relative z-10"
        >
        </motion.div>
      </div>
      
      {/* Animated Logo */}
      <div className="flex justify-center -mt-8 relative z-20">
        <motion.div 
          whileHover="hover"
          variants={houseVariants}
          className="bg-white dark:bg-gray-700 rounded-full p-4 shadow-lg"
        >
          <svg width="64" height="64" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M3 21H21" stroke="#6B46C1" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
            <path d="M5 21V7L12 3L19 7V21" stroke="#6B46C1" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
            <path d="M9 21V15H15V21" stroke="#6B46C1" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
            <path d="M9 10H10M14 10H15" stroke="#6B46C1" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
            <motion.path 
              d="M12 3V7"
              stroke="#4CAF50" 
              strokeWidth="2" 
              strokeLinecap="round"
              initial={{ pathLength: 0 }}
              animate={{ pathLength: 1 }}
              transition={{ duration: 1, repeat: Infinity, repeatType: "reverse" }}
            />
          </svg>
        </motion.div>
      </div>
      
      {/* Welcome Message */}
      <div className="text-center px-6 py-4">
        <h2 className="text-xl font-semibold text-gray-800 dark:text-white">Welcome to Ate by RealEst</h2>
      </div>
      
      {/* Sign In Form */}
      <div className="px-6 py-2">
        <form onSubmit={handleSignIn} className="space-y-4">
          <div>
            <label htmlFor="email" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Email
            </label>
            <input
              type="email"
              id="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm 
                        focus:outline-none focus:ring-primary-purple focus:border-primary-purple
                        dark:bg-gray-700 dark:text-white"
              placeholder="your@email.com"
              required
            />
          </div>
          
          <div>
            <label htmlFor="password" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Password
            </label>
            <input
              type="password"
              id="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm 
                        focus:outline-none focus:ring-primary-purple focus:border-primary-purple
                        dark:bg-gray-700 dark:text-white"
              placeholder="••••••••"
              required
            />
          </div>
          
          <div>
            <button
              type="submit"
              disabled={isLoading}
              className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm 
                        text-sm font-medium text-white bg-primary-purple hover:bg-purple-700 
                        focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-purple
                        transition-colors duration-200 disabled:opacity-70"
            >
              {isLoading ? (
                <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
              ) : null}
              {isLoading ? 'Signing in...' : 'Sign in'}
            </button>
          </div>
          
          <div className="text-center">
            <a href="#" className="text-sm text-primary-purple hover:text-purple-700 dark:text-purple-400 dark:hover:text-purple-300">
              Forgot your password?
            </a>
          </div>
        </form>
        
        <div className="mt-6 text-center">
          <p className="text-sm text-gray-600 dark:text-gray-400">
            Don't have an account?{' '}
            <a href="#" className="font-medium text-primary-purple hover:text-purple-700 dark:text-purple-400 dark:hover:text-purple-300">
              Sign up
            </a>
          </p>
        </div>
      </div>
      
      {/* Footer */}
      <div className="absolute bottom-0 left-0 right-0 text-center py-2 text-xs text-gray-500 dark:text-gray-400">
        RealEst Cashflow Analysis © 2025
      </div>
    </div>
  );
};

export default withErrorBoundary(
  withSuspense(Popup, <div className="w-full h-full flex items-center justify-center bg-white dark:bg-gray-800">Loading...</div>), 
  <div className="w-full h-full flex items-center justify-center bg-white dark:bg-gray-800 text-red-500">An error occurred</div>
);