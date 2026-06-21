<script lang="ts">
	import type { PageData } from './$types';
	import { Users, User, FileText, Video, Building, TrendingUp, Calendar } from 'lucide-svelte';
	import { onMount } from 'svelte';

	export let data: PageData;

	let totalHomeworks = 0;
	let totalCheckIns = 0;
	let totalReviews = 0;

	onMount(async () => {
		if (!data.profile?.institution_id) return;

		const { data: usersData } = await data.supabase
			.from('profiles')
			.select('id')
			.eq('institution_id', data.profile.institution_id)
			.eq('role', 'therapist');

		const therapistIds = (usersData || []).map((u) => u.id);
		if (therapistIds.length > 0) {
			const { count: hwCount } = await data.supabase
				.from('assigned_homeworks')
				.select('*', { count: 'exact', head: true })
				.in('therapist_id', therapistIds);
			totalHomeworks = hwCount || 0;

			const { data: childrenData } = await data.supabase
				.from('children')
				.select('id')
				.in('therapist_id', therapistIds);
			const childIds = (childrenData || []).map((c) => c.id);

			if (childIds.length > 0) {
				const { count: ciCount } = await data.supabase
					.from('check_ins')
					.select('*', { count: 'exact', head: true })
					.in('child_id', childIds);
				totalCheckIns = ciCount || 0;

				const { count: rvCount } = await data.supabase
					.from('reviews')
					.select('*', { count: 'exact', head: true });
				totalReviews = rvCount || 0;
			}
		}
	});

	const roleLabels: Record<string, string> = {
		admin: '管理员',
		therapist: '治疗师',
		parent: '家长'
	};

	const roleColors: Record<string, string> = {
		admin: 'bg-purple-100 text-purple-700',
		therapist: 'bg-green-100 text-green-700',
		parent: 'bg-blue-100 text-blue-700'
	};
</script>

<div class="max-w-6xl mx-auto px-4 py-8">
	<div class="mb-8">
		<h1 class="text-2xl font-bold text-gray-900 mb-2">
			管理员控制台 👋
		</h1>
		{#if data.institution}
			<p class="text-gray-500 flex items-center">
				<Building class="w-4 h-4 mr-1" />
				{data.institution.name}
			</p>
		{/if}
	</div>

	<div class="grid md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
		<div class="card p-6">
			<div class="flex items-center justify-between mb-4">
				<div>
					<p class="text-gray-500 text-sm">用户总数</p>
					<p class="text-3xl font-bold text-gray-900">{data.users?.length || 0}</p>
				</div>
				<div class="w-12 h-12 bg-blue-100 rounded-xl flex items-center justify-center">
					<Users class="w-6 h-6 text-blue-600" />
				</div>
			</div>
			<a href="/admin/users" class="text-primary-600 text-sm font-medium">管理用户 →</a>
		</div>

		<div class="card p-6">
			<div class="flex items-center justify-between mb-4">
				<div>
					<p class="text-gray-500 text-sm">治疗师</p>
					<p class="text-3xl font-bold text-gray-900">{data.therapists?.length || 0}</p>
				</div>
				<div class="w-12 h-12 bg-green-100 rounded-xl flex items-center justify-center">
					<User class="w-6 h-6 text-green-600" />
				</div>
			</div>
			<p class="text-gray-400 text-sm">在职治疗师人数</p>
		</div>

		<div class="card p-6">
			<div class="flex items-center justify-between mb-4">
				<div>
					<p class="text-gray-500 text-sm">孩子</p>
					<p class="text-3xl font-bold text-gray-900">{data.children?.length || 0}</p>
				</div>
				<div class="w-12 h-12 bg-orange-100 rounded-xl flex items-center justify-center">
					<Calendar class="w-6 h-6 text-orange-500" />
				</div>
			</div>
			<p class="text-gray-400 text-sm">注册孩子人数</p>
		</div>

		<div class="card p-6">
			<div class="flex items-center justify-between mb-4">
				<div>
					<p class="text-gray-500 text-sm">打卡/评审</p>
					<p class="text-3xl font-bold text-gray-900">{totalCheckIns}/{totalReviews}</p>
				</div>
				<div class="w-12 h-12 bg-purple-100 rounded-xl flex items-center justify-center">
					<TrendingUp class="w-6 h-6 text-purple-600" />
				</div>
			</div>
			<p class="text-gray-400 text-sm">布置作业：{totalHomeworks}</p>
		</div>
	</div>

	<div class="grid md:grid-cols-2 gap-6">
		<div class="card p-6">
			<div class="flex items-center justify-between mb-4">
				<h2 class="text-lg font-semibold text-gray-900">最近用户</h2>
				<a href="/admin/users" class="text-primary-600 text-sm font-medium">全部 →</a>
			</div>
			{#if data.users && data.users.length > 0}
				<div class="space-y-3">
					{#each data.users.slice(0, 5) as user}
						<div class="flex items-center p-3 bg-gray-50 rounded-lg">
							<div class="w-10 h-10 bg-gray-200 rounded-full flex items-center justify-center text-gray-600 font-medium">
								{user.full_name[0]}
							</div>
							<div class="ml-3 flex-1">
								<p class="font-medium text-gray-900">{user.full_name}</p>
								<p class="text-xs text-gray-500">{user.phone || '未设置手机号'}</p>
							</div>
							<span class={`badge ${roleColors[user.role]}`}>{roleLabels[user.role]}</span>
						</div>
					{/each}
				</div>
			{:else}
				<p class="text-gray-500 text-center py-8">暂无用户</p>
			{/if}
		</div>

		<div class="card p-6">
			<h2 class="text-lg font-semibold text-gray-900 mb-4">快速入口</h2>
			<div class="grid grid-cols-2 gap-3">
				<a href="/admin/users" class="p-4 bg-blue-50 rounded-xl hover:bg-blue-100 transition-colors">
					<Users class="w-8 h-8 text-blue-600 mb-2" />
					<p class="font-medium text-gray-900">用户管理</p>
					<p class="text-xs text-gray-500">添加/编辑用户</p>
				</a>
				<a href="/admin/settings" class="p-4 bg-purple-50 rounded-xl hover:bg-purple-100 transition-colors">
					<Building class="w-8 h-8 text-purple-600 mb-2" />
					<p class="font-medium text-gray-900">机构设置</p>
					<p class="text-xs text-gray-500">机构信息配置</p>
				</a>
			</div>
		</div>
	</div>
</div>
