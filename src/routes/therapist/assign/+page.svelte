<script lang="ts">
	import type { PageData } from './$types';
	import type { Child, ExerciseType, HomeworkTemplate } from '$lib/types';
	import { ExerciseTypeLabels, ExerciseTypeColors } from '$lib/types';
	import { ArrowLeft, Save, Calendar, Search } from 'lucide-svelte';
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';

	export let data: PageData;

	let selectedTemplateId = '';
	let selectedChildId = '';
	let title = '';
	let description = '';
	let exerciseType: ExerciseType = 'pronunciation';
	let startDate = new Date().toISOString().split('T')[0];
	let endDate = '';
	let frequency = 3;
	let templates: HomeworkTemplate[] = [];
	let templateSearch = '';
	let loading = false;

	const exerciseTypeList: ExerciseType[] = ['pronunciation', 'fine_motor', 'sensory'];

	$: filteredTemplates = templates.filter((t) =>
		t.title.toLowerCase().includes(templateSearch.toLowerCase())
	);

	$: selectedTemplate = templates.find((t) => t.id === selectedTemplateId);

	onMount(async () => {
		const templateId = $page.url.searchParams.get('templateId');
		const childId = $page.url.searchParams.get('childId');

		if (templateId) selectedTemplateId = templateId;
		if (childId) selectedChildId = childId;

		const nextWeek = new Date();
		nextWeek.setDate(nextWeek.getDate() + 14);
		endDate = nextWeek.toISOString().split('T')[0];

		const { data: tplData } = await data.supabase
			.from('homework_templates')
			.select('*')
			.or(`therapist_id.eq.${data.profile?.id},is_public.eq.true`)
			.order('created_at', { ascending: false });

		templates = tplData || [];

		if (selectedTemplate) {
			title = selectedTemplate.title;
			description = selectedTemplate.description || '';
			exerciseType = selectedTemplate.exercise_type;
		}
	});

	$: if (selectedTemplate) {
		title = selectedTemplate.title;
		description = selectedTemplate.description || '';
		exerciseType = selectedTemplate.exercise_type;
	}

	async function assignHomework() {
		if (!selectedChildId) {
			alert('请选择患者');
			return;
		}
		if (!title.trim()) {
			alert('请输入作业标题');
			return;
		}

		loading = true;

		try {
			const { error } = await data.supabase.from('assigned_homeworks').insert({
				template_id: selectedTemplateId || null,
				child_id: selectedChildId,
				therapist_id: data.profile?.id,
				title,
				description,
				exercise_type: exerciseType,
				start_date: startDate,
				end_date: endDate,
				frequency_per_week: frequency,
				status: 'pending'
			});

			if (error) throw error;

			alert('作业布置成功！');
			await goto('/therapist/patients');
		} catch (err) {
			console.error(err);
			alert('布置失败，请重试');
		} finally {
			loading = false;
		}
	}
</script>

<div class="max-w-4xl mx-auto px-4 py-8">
	<div class="flex items-center mb-6">
		<button on:click={() => history.back()} class="p-2 hover:bg-gray-100 rounded-lg mr-2">
			<ArrowLeft class="w-5 h-5" />
		</button>
		<div>
			<h1 class="text-2xl font-bold text-gray-900">布置作业</h1>
			<p class="text-gray-500 text-sm">为患者布置家庭训练作业</p>
		</div>
	</div>

	<div class="card p-6 mb-6">
		<h2 class="text-lg font-semibold text-gray-900 mb-4">1. 选择患者</h2>
		{#if data.patients && data.patients.length > 0}
			<div class="grid grid-cols-2 md:grid-cols-3 gap-3">
				{#each data.patients as patient}
					<button
						type="button"
						on:click={() => (selectedChildId = patient.id)}
						class={`p-4 rounded-xl text-left transition-all border-2 {
							selectedChildId === patient.id
								? 'border-primary-500 bg-primary-50'
								: 'border-gray-200 hover:border-gray-300'
						}`}
					>
						<div class="flex items-center">
							<div class="w-10 h-10 bg-gradient-to-br from-primary-400 to-primary-600 rounded-full flex items-center justify-center text-white font-medium">
								{patient.name[0]}
							</div>
							<div class="ml-3">
								<p class="font-medium text-gray-900">{patient.name}</p>
								{#if patient.nickname}
									<p class="text-xs text-gray-500">{patient.nickname}</p>
								{/if}
							</div>
						</div>
					</button>
				{/each}
			</div>
		{:else}
			<p class="text-gray-500">暂无患者，请先在管理员处添加患者</p>
		{/if}
	</div>

	<div class="card p-6 mb-6">
		<div class="flex items-center justify-between mb-4">
			<h2 class="text-lg font-semibold text-gray-900">2. 选择作业模板（可选）</h2>
		</div>
		<div class="relative mb-4">
			<Search class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
			<input
				type="text"
				bind:value={templateSearch}
				class="input pl-10"
				placeholder="搜索模板..."
			/>
		</div>
		{#if filteredTemplates.length === 0}
			<p class="text-gray-500 text-center py-4">暂无模板，可手动填写作业内容</p>
		{:else}
			<div class="grid md:grid-cols-2 gap-3 max-h-80 overflow-y-auto">
				<button
					type="button"
					on:click={() => (selectedTemplateId = '')}
					class={`p-4 rounded-xl text-left transition-all border-2 {
						!selectedTemplateId
							? 'border-gray-400 bg-gray-50'
							: 'border-gray-200 hover:border-gray-300'
					}`}
				>
					<p class="font-medium text-gray-900">不使用模板</p>
					<p class="text-xs text-gray-500">手动填写作业内容</p>
				</button>
				{#each filteredTemplates as tpl}
					<button
						type="button"
						on:click={() => (selectedTemplateId = tpl.id)}
						class={`p-4 rounded-xl text-left transition-all border-2 {
							selectedTemplateId === tpl.id
								? 'border-primary-500 bg-primary-50'
								: 'border-gray-200 hover:border-gray-300'
						}`}
					>
						<div class="flex items-center gap-2 mb-1">
							<span class={`badge ${ExerciseTypeColors[tpl.exercise_type]}`}>
								{ExerciseTypeLabels[tpl.exercise_type]}
							</span>
						</div>
						<p class="font-medium text-gray-900">{tpl.title}</p>
						{#if tpl.description}
							<p class="text-xs text-gray-500 line-clamp-1">{tpl.description}</p>
						{/if}
					</button>
				{/each}
			</div>
		{/if}
	</div>

	<div class="card p-6 mb-6">
		<h2 class="text-lg font-semibold text-gray-900 mb-4">3. 作业详情</h2>
		<div class="space-y-4">
			<div>
				<label for="homework-title" class="label">作业标题 *</label>
				<input id="homework-title" type="text" bind:value={title} class="input" required />
			</div>

			<fieldset>
				<legend class="label">训练类型 *</legend>
				<div class="grid grid-cols-3 gap-3">
					{#each exerciseTypeList as type}
						<button
							type="button"
							on:click={() => (exerciseType = type)}
							class={`px-4 py-3 rounded-lg text-sm font-medium transition-colors border {
								exerciseType === type
									? 'bg-primary-500 text-white border-primary-500'
									: 'bg-white text-gray-700 border-gray-300 hover:bg-gray-50'
							}`}
						>
							{ExerciseTypeLabels[type]}
						</button>
					{/each}
				</div>
			</fieldset>

			<div>
				<label for="homework-description" class="label">作业说明</label>
				<textarea
					id="homework-description"
					bind:value={description}
					class="input min-h-[100px]"
					placeholder="为家长说明本次训练的要点和注意事项..."
				/>
			</div>

			<div class="grid md:grid-cols-3 gap-4">
				<div>
					<label for="start-date" class="label">开始日期 *</label>
					<div class="relative">
						<Calendar class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
						<input id="start-date" type="date" bind:value={startDate} class="input pl-10" required />
					</div>
				</div>
				<div>
					<label for="end-date" class="label">结束日期 *</label>
					<div class="relative">
						<Calendar class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
						<input id="end-date" type="date" bind:value={endDate} class="input pl-10" required />
					</div>
				</div>
				<div>
					<label for="frequency" class="label">每周频次</label>
					<select id="frequency" bind:value={frequency} class="input">
						{#each [1, 2, 3, 4, 5, 6, 7] as n}
							<option value={n}>每周 {n} 次</option>
						{/each}
					</select>
				</div>
			</div>
		</div>
	</div>

	<div class="flex justify-end gap-3">
		<button on:click={() => history.back()} class="btn btn-secondary">
			取消
		</button>
		<button on:click={assignHomework} class="btn btn-primary" disabled={loading}>
			<Save class="w-5 h-5 mr-2" />
			{loading ? '布置中...' : '确认布置'}
		</button>
	</div>
</div>
