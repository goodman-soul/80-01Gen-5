<script lang="ts">
	import '../app.css';
	import { page } from '$app/stores';
	import type { PageData } from './$types';
	import Nav from '$lib/components/Nav.svelte';

	export let data: PageData;

	$: isAuthPage = ['/login', '/register'].includes($page.url.pathname);
</script>

<div class="min-h-screen bg-gray-50">
	{#if !isAuthPage && data.session}
		<Nav {data} />
	{/if}
	<main class={isAuthPage || !data.session ? '' : 'pb-20 md:pb-0 md:ml-64'}>
		<slot />
	</main>
</div>
