<script lang="ts">
	import type { PageData } from './$types';
	import { Users, FileText, Video, Calendar, ClipboardList, TrendingUp } from 'lucide-svelte';
	import { onMount } from 'svelte';

	export let data: PageData;

	let pendingReviews = 0;
	let assignedThisWeek = 0;

	onMount(async () => {
		if (!data.profile) return;

		const { count: reviewCount } = await data.supabase
			.from('check_ins')
			.select('*', { count: 'exact', head: true })
			.not('id', 'in', (await data.supabase.from('reviews').select('check_in_id')).data?.map((r) => r.check_in_id) || []);

		pendingReviews = reviewCount || 0;

		const weekAgo = new Date();
		weekAgo.setDate(weekAgo.getDate() - 7);
		const { count: hwCount } = await data.supabase
			.from('assigned_homeworks')
			.select('*', { count: 'exact', head: true })
			.eq('therapist_id', data.profile.id)
			.gte('created_at', weekAgo.toISOString());

		assignedThisWeek = hwCount || 0;
	});
</script>

<div class="max-w-6xl mx-auto px-4 py-8">
	<div class="mb-8">
		<h1 class="text-2xl font-bold text-gray-900 mb-2">
			你好，{data.profile?.full_name || '治疗师'} 医生 👋
		</h1>
		<p class="text-gray-500">今天是 {new Date().toLocaleDateString('zh-CN', { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' })}</p>
	</div>

	<div class="grid md:grid-cols-4 gap-4 mb-8">
		<div class="card p-6">
			<div class="flex items-center justify-between mb-4">
				<div>
					<p class="text-gray-500 text-sm">我的患者</p>
					<p class="text-3xl font-bold text-gray-900">{data.patients?.length || 0}</p>
				</div>
				<div class="w-12 h-12 bg-blue-100 rounded-xl flex items-center justify-center">
					<Users class="w-6 h-6 text-blue-600" />
				</div>
			</div>
			<a href="/therapist/patients" class="text-primary-600 text-sm font-medium">查看患者 →</a>
		</div>

		<div class="card p-6">
			<div class="flex items-center justify-between mb-4">
				<div>
					<p class="text-gray-500 text-sm">待评审打卡</p>
					<p class="text-3xl font-bold text-gray-900">{pendingReviews}</p>
				</div>
				<div class="w-12 h-12 bg-orange-100 rounded-xl flex items-center justify-center">
					<Video class="w-6 h-6 text-orange-500" />
				</div>
			</div>
			<a href="/therapist/reviews" class="text-primary-600 text-sm font-medium">立即评审 →</a>
		</div>

		<div class="card p-6">
			<div class="flex items-center justify-between mb-4">
				<div>
					<p class="text-gray-500 text-sm">本周布置作业</p>
					<p class="text-3xl font-bold text-gray-900">{assignedThisWeek}</p>
				</div>
				<div class="w-12 h-12 bg-green-100 rounded-xl flex items-center justify-center">
					<ClipboardList class="w-6 h-6 text-green-600" />
				</div>
			</div>
			<a href="/therapist/templates" class="text-primary-600 text-sm font-medium">作业模板 →</a>
		</div>

		<div class="card p-6">
			<div class="flex items-center justify-between mb-4">
				<div>
					<p class="text-gray-500 text-sm">完成率</p>
					<p class="text-3xl font-bold text-gray-900">--%</p>
				</div>
				<div class="w-12 h-12 bg-purple-100 rounded-xl flex items-center justify-center">
					<TrendingUp class="w-6 h-6 text-purple-600" />
				</div>
			</div>
			<p class="text-gray-400 text-sm">统计数据更新中</p>
		</div>
	</div>

	<div class="grid md:grid-cols-2 gap-6">
		<div class="card p-6">
			<div class="flex items-center justify-between mb-4">
				<h2 class="text-lg font-semibold text-gray-900">我的患者</h2>
				<a href="/therapist/patients" class="text-primary-600 text-sm font-medium">全部 →</a>
			</div>
			{#if data.patients && data.patients.length > 0}
				<div class="space-y-3">
					{#each data.patients.slice(0, 5) as patient}
						<div class="flex items-center p-3 bg-gray-50 rounded-lg">
							<div class="w-10 h-10 bg-gradient-to-br from-primary-400 to-primary-600 rounded-full flex items-center justify-center text-white font-medium">
								{patient.name[0]}
							</div>
							<div class="ml-3 flex-1">
								<p class="font-medium text-gray-900">{patient.name}</p>
								<p class="text-xs text-gray-500">
									{patient.nickname || ''}
								</p>
							</div>
							<a href={`/therapist/patients/${patient.id}`} class="text-primary-600 text-sm">
								详情 →
							</a>
						</div>
					{/each}
				</div>
			{:else}
				<p class="text-gray-500 text-center py-8">暂无患者</p>
			{/if}
		</div>

		<div class="card p-6">
			<div class="flex items-center justify-between mb-4">
				<h2 class="text-lg font-semibold text-gray-900">快捷操作</h2>
			</div>
			<div class="grid grid-cols-2 gap-3">
				<a href="/therapist/templates" class="p-4 bg-primary-50 rounded-xl hover:bg-primary-100 transition-colors">
					<FileText class="w-8 h-8 text-primary-600 mb-2" />
					<p class="font-medium text-gray-900">创建作业模板</p>
					<p class="text-xs text-gray-500">设置标准训练步骤</p>
				</a>
				<a href="/therapist/reviews" class="p-4 bg-orange-50 rounded-xl hover:bg-orange-100 transition-colors">
					<Video class="w-8 h-8 text-orange-500 mb-2" />
					<p class="font-medium text-gray-900">评审打卡</p>
					<p class="text-xs text-gray-500">查看视频标注反馈</p>
				</a>
			</div>
		</div>
	</div>
</div>
