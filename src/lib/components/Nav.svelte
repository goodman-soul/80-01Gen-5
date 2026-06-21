<script lang="ts">
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import type { Profile } from '$lib/types';
	import type { SupabaseClient } from '@supabase/supabase-js';
	import {
		Home,
		FileText,
		Users,
		Video,
		ClipboardList,
		LogOut,
		UserCog,
		Building
	} from 'lucide-svelte';

	interface NavData {
		session: { user: { id: string } } | null;
		profile: Profile | null;
		supabase: SupabaseClient;
	}

	export let data: NavData;

	const parentNav = [
		{ label: '首页', href: '/parent', icon: Home },
		{ label: '我的作业', href: '/parent/homeworks', icon: FileText },
		{ label: '打卡记录', href: '/parent/checkins', icon: ClipboardList }
	];

	const therapistNav = [
		{ label: '首页', href: '/therapist', icon: Home },
		{ label: '我的患者', href: '/therapist/patients', icon: Users },
		{ label: '作业模板', href: '/therapist/templates', icon: FileText },
		{ label: '待评审', href: '/therapist/reviews', icon: Video }
	];

	const adminNav = [
		{ label: '首页', href: '/admin', icon: Home },
		{ label: '用户管理', href: '/admin/users', icon: UserCog },
		{ label: '机构设置', href: '/admin/settings', icon: Building }
	];

	$: navItems =
		data.profile?.role === 'parent'
			? parentNav
			: data.profile?.role === 'therapist'
				? therapistNav
				: data.profile?.role === 'admin'
					? adminNav
					: [];

	async function signOut() {
		await data.supabase.auth.signOut();
		await goto('/login');
	}
</script>

<nav class="hidden md:flex md:flex-col md:fixed md:inset-y-0 md:left-0 md:w-64 bg-white border-r border-gray-200">
	<div class="flex items-center h-16 px-6 border-b border-gray-200">
		<span class="text-xl font-bold text-primary-600">儿童康复训练</span>
	</div>
	<div class="flex-1 overflow-y-auto py-4">
		{#if data.profile}
			<div class="px-6 py-4 border-b border-gray-100 mb-4">
				<p class="text-sm font-medium text-gray-900">{data.profile.full_name}</p>
				<p class="text-xs text-gray-500">
					{data.profile.role === 'parent'
						? '家长'
						: data.profile.role === 'therapist'
							? '治疗师'
							: '管理员'}
				</p>
			</div>
		{/if}
		<nav class="px-3 space-y-1">
			{#each navItems as item}
				<a
					href={item.href}
					class="flex items-center px-3 py-2 text-sm font-medium rounded-lg transition-colors {
						$page.url.pathname === item.href
							? 'bg-primary-50 text-primary-600'
							: 'text-gray-700 hover:bg-gray-50 hover:text-gray-900'
					}"
				>
					<svelte:component this={item.icon} class="w-5 h-5 mr-3" />
					{item.label}
				</a>
			{/each}
		</nav>
	</div>
	<div class="p-4 border-t border-gray-200">
		<button on:click={signOut} class="flex items-center w-full px-3 py-2 text-sm font-medium text-gray-700 rounded-lg hover:bg-gray-50">
			<LogOut class="w-5 h-5 mr-3" />
			退出登录
		</button>
	</div>
</nav>

<nav class="md:hidden fixed bottom-0 inset-x-0 bg-white border-t border-gray-200">
	<div class="flex justify-around">
		{#each navItems as item}
			<a
				href={item.href}
				class="flex flex-col items-center py-2 px-4 text-xs transition-colors {
					$page.url.pathname === item.href ? 'text-primary-600' : 'text-gray-500'
				}"
			>
				<svelte:component this={item.icon} class="w-6 h-6 mb-1" />
				{item.label}
			</a>
		{/each}
	</div>
</nav>
