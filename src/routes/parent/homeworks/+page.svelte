<script lang="ts">
	import type { PageData } from './$types';
	import type { AssignedHomework, Child } from '$lib/types';
	import { ExerciseTypeLabels, ExerciseTypeColors, HomeworkStatusLabels } from '$lib/types';
	import { Calendar, Clock, ArrowRight, FileText } from 'lucide-svelte';
	import { onMount } from 'svelte';

	export let data: PageData;

	let homeworks: AssignedHomework[] = [];
	let loading = true;
	let selectedChildId = '';

	$: filteredHomeworks = selectedChildId
		? homeworks.filter((h) => h.child_id === selectedChildId)
		: homeworks;

	onMount(async () => {
		if (data.children && data.children.length > 0) {
			const childIds = data.children.map((c) => c.id);
			const { data: hwData } = await data.supabase
				.from('assigned_homeworks')
				.select('*, child:children(*)')
				.in('child_id', childIds)
				.order('created_at', { ascending: false });
			homeworks = hwData || [];
		}
		loading = false;
	});

	function getStatusColor(status: string) {
		switch (status) {
			case 'pending':
				return 'bg-gray-100 text-gray-700';
			case 'in_progress':
				return 'bg-blue-100 text-blue-700';
			case 'completed':
				return 'bg-green-100 text-green-700';
			case 'reviewed':
				return 'bg-purple-100 text-purple-700';
			default:
				return 'bg-gray-100 text-gray-700';
		}
	}
</script>

<div class="max-w-6xl mx-auto px-4 py-8">
	<div class="flex items-center justify-between mb-6">
		<div>
			<h1 class="text-2xl font-bold text-gray-900">我的作业</h1>
			<p class="text-gray-500 text-sm">查看治疗师布置的训练作业</p>
		</div>
	</div>

	{#if data.children && data.children.length > 1}
		<div class="mb-6">
			<label class="label">选择孩子</label>
			<select bind:value={selectedChildId} class="input max-w-xs">
				<option value="">全部</option>
				{#each data.children as child}
					<option value={child.id}>{child.name}</option>
				{/each}
			</select>
		</div>
	{/if}

	{#if loading}
		<div class="flex justify-center py-12">
			<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500" />
		</div>
	{:else if filteredHomeworks.length === 0}
		<div class="card p-12 text-center">
			<FileText class="w-16 h-16 text-gray-300 mx-auto mb-4" />
			<p class="text-gray-500 mb-2">暂无作业</p>
			<p class="text-sm text-gray-400">治疗师布置的作业会显示在这里</p>
		</div>
	{:else}
		<div class="space-y-4">
			{#each filteredHomeworks as hw}
				<a href={`/parent/homeworks/${hw.id}`} class="card p-6 block hover:shadow-md transition-shadow">
					<div class="flex items-start justify-between">
						<div class="flex-1">
							<div class="flex items-center gap-2 mb-2">
								<span class={`badge ${ExerciseTypeColors[hw.exercise_type]}`}>
									{ExerciseTypeLabels[hw.exercise_type]}
								</span>
								<span class={`badge ${getStatusColor(hw.status)}`}>
									{HomeworkStatusLabels[hw.status]}
								</span>
							</div>
							<h3 class="text-lg font-semibold text-gray-900 mb-1">{hw.title}</h3>
							{#if hw.description}
								<p class="text-gray-600 text-sm line-clamp-2 mb-3">{hw.description}</p>
							{/if}
							<div class="flex items-center gap-4 text-sm text-gray-500">
								{#if hw.child}
									<span class="flex items-center">
										<div class="w-5 h-5 bg-primary-100 rounded-full mr-1.5 flex items-center justify-center text-xs text-primary-600">
											{hw.child.name[0]}
										</div>
										{hw.child.name}
									</span>
								{/if}
								<span class="flex items-center">
									<Calendar class="w-4 h-4 mr-1" />
									{hw.start_date} ~ {hw.end_date}
								</span>
								<span class="flex items-center">
									<Clock class="w-4 h-4 mr-1" />
									每周 {hw.frequency_per_week} 次
								</span>
							</div>
						</div>
						<ArrowRight class="w-5 h-5 text-gray-400" />
					</div>
				</a>
			{/each}
		</div>
	{/if}
</div>
