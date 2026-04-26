import { test, expect } from '@playwright/test';

test('should load images from posts', async ({ page }) => {
  await page.goto('http://localhost:4321');
  
  // Check images are visible
  const img1 = page.locator('img[alt*="Bigme"]');
  const img2 = page.locator('img[alt="Demo Video"]');
  
  await expect(img1).toBeVisible();
  await expect(img2).toBeVisible();
  
  // Verify src attributes
  await expect(img1).toHaveAttribute('src', /post-01\.png/);
  await expect(img2).toHaveAttribute('src', /post-02\.gif/);
});
