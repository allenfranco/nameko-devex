import { sveltekit } from '@sveltejs/kit/vite'

/** @type {import('vite').UserConfig} */
const config = {
	plugins: [sveltekit()],
	test: {
		globals: true,
		environment: 'jsdom',
		include: ['src/**/*.{test.spec}.ts'],
		setupFiles: ['./setupTest.js'],
	},
	server: {
		port: 3000
	},
}

export default config
