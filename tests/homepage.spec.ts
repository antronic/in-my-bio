import { test, expect } from '@playwright/test';

test.describe('in-my-bio Homepage', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  test('should load the homepage', async ({ page }) => {
    await expect(page).toHaveTitle(/job.jirachai/);
  });

  test('should display profile section', async ({ page }) => {
    await expect(page.locator('img[alt="@job.jirachai"]')).toBeVisible();
    await expect(page.getByRole('link', { name: '@job.jirachai' })).toBeVisible();
  });

  test('should display link cards from posts.json', async ({ page }) => {
    const cards = page.locator('a[target="_blank"]');
    await expect(cards.first()).toBeVisible();
    await expect(page.getByRole('heading', { name: /Bigme B7 Pro/i })).toBeVisible();
  });

  test('should have working links', async ({ page }) => {
    const firstCard = page.locator('a[target="_blank"]').first();
    await expect(firstCard).toHaveAttribute('href', /https?:\/\//);
  });
});
