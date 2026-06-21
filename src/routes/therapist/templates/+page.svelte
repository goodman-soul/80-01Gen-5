<script lang="ts">
	import type { PageData } from './$types';
	import type { HomeworkTemplate } from '$lib/types';
	import { ExerciseTypeLabels, ExerciseTypeColors } from '$lib/types';
	import { Search, Plus, FileText, Edit, Trash2, Copy } from 'lucide-svelte';
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';

	export let data: PageData;

	let templates: HomeworkTemplate[] = [];
	let loading = true;
	let searchQuery = '';
	let selectedType = '';

	$: filteredTemplates = templates.filter((t) => {
		const matchSearch = t.title.toLowerCase().includes(searchQuery.toLowerCase());
		const matchType = selectedType ? t.exercise_type === selectedType : true;
		return matchSearch && matchType;
	});

	onMount(async () => {
		const { data: tplData } = await data.supabase
			.from('homework_templates')
			.select('*')
			.or(`therapist_id.eq.${data.profile?.id},is_public.eq.true`)
			.order('created_at', { ascending: false });

		templates = tplData || [];
		loading = false;
	});

	async function deleteTemplate(id: string) {
		if (!confirm('确定要删除这个作业模板吗？')) return;

		const { error } = await data.supabase
			.from('homework_templates')
			.delete()
			.eq('id', id)
			.eq('therapist_id', data.profile?.id);

		if (error) {
			alert('删除失败');
			return;
		}

		templates = templates.filter((t) => t.id !== id);
	}
</script>

<div class="max-w-6xl mx-auto px-4 py-8">
	<div class="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-6 gap-4">
		<div>
			<h1 class="text-2xl font-bold text-gray-900">作业模板</h1>
			<p class="text-gray-500 text-sm">创建和管理训练作业模板</p>
		</div>
		<button on:click={() => goto('/therapist/templates/new')} class="btn btn-primary">
			<Plus class="w-5 h-5 mr-2" />
			新建模板
		</button>
	</div>

	<div class="flex flex-col sm:flex-row gap-4 mb-6">
		<div class="relative flex-1 max-w-sm">
			<Search class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
			<input
				type="text"
				bind:value={searchQuery}
				class="input pl-10 w-full"
				placeholder="搜索模板..."
			/>
		</div>
		<div class="flex gap-2 flex-wrap">
			<button
				on:click={() => (selectedType = '')}
				class={`px-4 py-2 rounded-lg text-sm font-medium transition-colors {
					selectedType === ''
						? 'bg-primary-500 text-white'
						: 'bg-white text-gray-700 border border-gray-300 hover:bg-gray-50'
				}`}
			>
				全部
			</button>
			{#each (['pronunciation', 'fine_motor', 'sensory'] as const) as type}
				<button
					on:click={() => (selectedType = type)}
					class={`px-4 py-2 rounded-lg text-sm font-medium transition-colors {
						selectedType === type
							? 'bg-primary-500 text-white'
							: 'bg-white text-gray-700 border border-gray-300 hover:bg-gray-50'
					}`}
				>
					{ExerciseTypeLabels[type]}
				</button>
			{/each}
		</div>
	</div>

	{#if loading}
		<div class="flex justify-center py-12">
			<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500" />
		</div>
	{:else if filteredTemplates.length === 0}
		<div class="card p-12 text-center">
			<FileText class="w-16 h-16 text-gray-300 mx-auto mb-4" />
			<p class="text-gray-500 mb-2">
				{searchQuery || selectedType ? '未找到匹配的模板' : '暂无作业模板'}
			</p>
			<p class="text-sm text-gray-400">点击"新建模板"创建第一个训练模板</p>
		</div>
	{:else}
		<div class="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
			{#each filteredTemplates as tpl}
				<div class="card p-6 hover:shadow-md transition-shadow">
					<div class="flex items-start justify-between mb-3">
						<span class={`badge ${ExerciseTypeColors[tpl.exercise_type]}`}>
							{ExerciseTypeLabels[tpl.exercise_type]}
						</span>
						{#if tpl.therapist_id !== data.profile?.id}
							<span class="badge bg-blue-100 text-blue-700">公开</span>
						{/if}
					</div>
					<h3 class="text-lg font-semibold text-gray-900 mb-2">{tpl.title}</h3>
					{#if tpl.description}
						<p class="text-sm text-gray-600 line-clamp-2 mb-4">{tpl.description}</p>
					{/if}

					<div class="flex gap-2">
						<a
							href={`/therapist/templates/${tpl.id}/edit`}
							class="btn btn-secondary flex-1 text-sm py-2"
						>
							<Edit class="w-4 h-4 mr-1" />
							编辑
						</a>
						<button
							on:click={() => goto(`/therapist/assign?templateId=${tpl.id}`)}
							class="btn btn-outline text-sm py-2"
						>
							<Copy class="w-4 h-4 mr-1" />
							布置
						</button>
						{#if tpl.therapist_id === data.profile?.id}
							<button
								on:click={() => deleteTemplate(tpl.id)}
								class="p-2 text-gray-400 hover:text-red-500 hover:bg-red-50 rounded-lg"
							>
								<Trash2 class="w-5 h-5" />
							</button>
						{/if}
					</div>
				</div>
			{/each}
		</div>
	{/if}
</div>
