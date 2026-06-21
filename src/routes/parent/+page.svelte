<script lang="ts">
	import type { PageData } from './$types';
	import { FileText, ClipboardList, CheckCircle, Clock, Calendar, User } from 'lucide-svelte';

	export let data: PageData;
</script>

<div class="max-w-6xl mx-auto px-4 py-8">
	<div class="mb-8">
		<h1 class="text-2xl font-bold text-gray-900 mb-2">欢迎回来，{data.profile?.full_name || '家长'} 👋</h1>
		<p class="text-gray-500">今天是 {new Date().toLocaleDateString('zh-CN', { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' })}</p>
	</div>

	<div class="grid md:grid-cols-3 gap-4 mb-8">
		<div class="card p-6">
			<div class="flex items-center justify-between mb-4">
				<div>
					<p class="text-gray-500 text-sm">今日待完成作业</p>
					<p class="text-3xl font-bold text-gray-900">0</p>
				</div>
				<div class="w-12 h-12 bg-orange-100 rounded-xl flex items-center justify-center">
					<ClipboardList class="w-6 h-6 text-orange-500" />
				</div>
			</div>
			<a href="/parent/homeworks" class="text-primary-600 text-sm font-medium">查看全部 →</a>
		</div>

		<div class="card p-6">
			<div class="flex items-center justify-between mb-4">
				<div>
					<p class="text-gray-500 text-sm">本周已打卡</p>
					<p class="text-3xl font-bold text-gray-900">0</p>
				</div>
				<div class="w-12 h-12 bg-green-100 rounded-xl flex items-center justify-center">
					<CheckCircle class="w-6 h-6 text-green-600" />
				</div>
			</div>
			<a href="/parent/checkins" class="text-primary-600 text-sm font-medium">查看记录 →</a>
		</div>

		<div class="card p-6">
			<div class="flex items-center justify-between mb-4">
				<div>
					<p class="text-gray-500 text-sm">关联孩子</p>
					<p class="text-3xl font-bold text-gray-900">{data.children?.length || 0}</p>
				</div>
				<div class="w-12 h-12 bg-blue-100 rounded-xl flex items-center justify-center">
					<User class="w-6 h-6 text-blue-600" />
				</div>
			</div>
			<p class="text-gray-400 text-sm">已添加 {data.children?.length || 0} 位孩子</p>
		</div>
	</div>

	{#if data.children && data.children.length > 0}
		<h2 class="text-xl font-semibold text-gray-900 mb-4">我的孩子</h2>
		<div class="grid md:grid-cols-2 gap-4 mb-8">
			{#each data.children as child}
				<div class="card p-6">
					<div class="flex items-center">
						<div class="w-14 h-14 bg-gradient-to-br from-primary-400 to-primary-600 rounded-full flex items-center justify-center text-white text-xl font-bold">
							{child.name[0]}
						</div>
						<div class="ml-4">
							<h3 class="font-semibold text-gray-900">{child.name}</h3>
							<p class="text-sm text-gray-500">
								{child.nickname || ''}
							</p>
						</div>
					</div>
				</div>
			{/each}
		</div>
	{:else}
		<div class="card p-8 text-center">
			<User class="w-16 h-16 text-gray-300 mx-auto mb-4" />
			<p class="text-gray-500 mb-4">还未添加孩子</p>
			<p class="text-sm text-gray-400">请联系机构管理员或治疗师添加孩子信息</p>
		</div>
	{/if}

	<h2 class="text-xl font-semibold text-gray-900 mb-4">最近作业</h2>
	<div class="card p-8 text-center">
		<FileText class="w-16 h-16 text-gray-300 mx-auto mb-4" />
		<p class="text-gray-500 mb-2">暂无待办作业</p>
		<p class="text-sm text-gray-400">治疗师布置的作业会显示在这里</p>
	</div>
</div>
