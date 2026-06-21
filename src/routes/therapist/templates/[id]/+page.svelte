<script lang="ts">
	import type { PageData } from './$types';
	import type { ExerciseType, HomeworkStep } from '$lib/types';
	import { ExerciseTypeLabels } from '$lib/types';
	import { Plus, Trash2, GripVertical, ArrowLeft, Save } from 'lucide-svelte';
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';

	export let data: PageData;

	let title = '';
	let description = '';
	let exerciseType: ExerciseType = 'pronunciation';
	let isPublic = false;
	let steps: HomeworkStep[] = [];
	let templateId: string | null = null;
	let loading = false;
	let isEdit = false;

	const exerciseTypeList: ExerciseType[] = ['pronunciation', 'fine_motor', 'sensory'];

	onMount(async () => {
		const id = data.params.id;
		if (id && id !== 'new') {
			templateId = id;
			isEdit = true;
			const { data: tplData } = await data.supabase
				.from('homework_templates')
				.select('*, steps:homework_steps(*)')
				.eq('id', id)
				.single();

			if (tplData) {
				title = tplData.title;
				description = tplData.description || '';
				exerciseType = tplData.exercise_type;
				isPublic = tplData.is_public;
				steps = (tplData.steps || []).sort((a, b) => a.step_number - b.step_number);
			}
		}
	});

	function addStep() {
		steps = [
			...steps,
			{
				id: `temp-${Date.now()}`,
				template_id: '',
				step_number: steps.length + 1,
				title: '',
				description: '',
				image_url: null,
				video_url: null,
				duration_seconds: 0,
				created_at: new Date().toISOString(),
				updated_at: new Date().toISOString()
			}
		];
	}

	function removeStep(index: number) {
		steps = steps.filter((_, i) => i !== index).map((s, i) => ({ ...s, step_number: i + 1 }));
	}

	function moveStep(index: number, direction: -1 | 1) {
		const newIndex = index + direction;
		if (newIndex < 0 || newIndex >= steps.length) return;

		const newSteps = [...steps];
		[newSteps[index], newSteps[newIndex]] = [newSteps[newIndex], newSteps[index]];
		steps = newSteps.map((s, i) => ({ ...s, step_number: i + 1 }));
	}

	async function saveTemplate() {
		if (!title.trim()) {
			alert('请输入作业标题');
			return;
		}
		if (steps.length === 0) {
			alert('请至少添加一个训练步骤');
			return;
		}
		if (steps.some((s) => !s.title.trim())) {
			alert('请填写所有步骤的标题');
			return;
		}

		loading = true;

		try {
			if (templateId) {
				const { error } = await data.supabase
					.from('homework_templates')
					.update({
						title,
						description,
						exercise_type: exerciseType,
						is_public: isPublic
					})
					.eq('id', templateId);

				if (error) throw error;

				const { error: delError } = await data.supabase
					.from('homework_steps')
					.delete()
					.eq('template_id', templateId);

				if (delError) throw delError;
			} else {
				const { data: newTpl, error } = await data.supabase
					.from('homework_templates')
					.insert({
						title,
						description,
						exercise_type: exerciseType,
						therapist_id: data.profile?.id,
						institution_id: data.profile?.institution_id,
						is_public: isPublic
					})
					.select()
					.single();

				if (error || !newTpl) throw error;
				templateId = newTpl.id;
			}

			const stepsToInsert = steps.map((s) => ({
				template_id: templateId,
				step_number: s.step_number,
				title: s.title,
				description: s.description,
				image_url: s.image_url,
				video_url: s.video_url,
				duration_seconds: s.duration_seconds
			}));

			const { error: stepError } = await data.supabase
				.from('homework_steps')
				.insert(stepsToInsert);

			if (stepError) throw stepError;

			alert('保存成功！');
			await goto('/therapist/templates');
		} catch (err) {
			console.error(err);
			alert('保存失败，请重试');
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
			<h1 class="text-2xl font-bold text-gray-900">{isEdit ? '编辑作业模板' : '新建作业模板'}</h1>
			<p class="text-gray-500 text-sm">创建标准化的训练作业，方便快速布置给患者</p>
		</div>
	</div>

	<div class="card p-6 mb-6">
		<div class="space-y-4">
			<div>
				<label class="label">作业标题 *</label>
				<input
					type="text"
					bind:value={title}
					class="input"
					placeholder="如：双唇音发音练习"
					required
				/>
			</div>

			<div>
				<label class="label">训练类型 *</label>
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
			</div>

			<div>
				<label class="label">作业描述</label>
				<textarea
					bind:value={description}
					class="input min-h-[100px]"
					placeholder="描述这个训练的目标和要点..."
				/>
			</div>

			<div class="flex items-center">
				<input
					type="checkbox"
					id="isPublic"
					bind:checked={isPublic}
					class="w-4 h-4 text-primary-600 rounded border-gray-300 focus:ring-primary-500"
				/>
				<label for="isPublic" class="ml-2 text-sm text-gray-700">
					设为公开模板（机构内其他治疗师可使用）
				</label>
			</div>
		</div>
	</div>

	<div class="card p-6 mb-6">
		<div class="flex items-center justify-between mb-4">
			<h2 class="text-lg font-semibold text-gray-900">训练步骤</h2>
			<button on:click={addStep} class="btn btn-primary text-sm">
				<Plus class="w-4 h-4 mr-2" />
				添加步骤
			</button>
		</div>

		{#if steps.length === 0}
			<div class="text-center py-8 border-2 border-dashed border-gray-200 rounded-xl">
				<p class="text-gray-500 mb-2">还没有步骤</p>
				<p class="text-sm text-gray-400">点击"添加步骤"开始创建训练流程</p>
			</div>
		{:else}
			<div class="space-y-4">
				{#each steps as step, index}
					<div class="border border-gray-200 rounded-xl p-4 bg-gray-50">
						<div class="flex items-start gap-3">
							<div class="flex flex-col items-center pt-2">
								<button
									on:click={() => moveStep(index, -1)}
									class="p-1 text-gray-400 hover:text-gray-600 disabled:opacity-30"
									disabled={index === 0}
								>
									<GripVertical class="w-5 h-5 rotate-90" />
								</button>
								<div class="w-8 h-8 bg-primary-500 text-white rounded-full flex items-center justify-center font-medium my-1">
									{index + 1}
								</div>
								<button
									on:click={() => moveStep(index, 1)}
									class="p-1 text-gray-400 hover:text-gray-600 disabled:opacity-30"
									disabled={index === steps.length - 1}
								>
									<GripVertical class="w-5 h-5 rotate-90" />
								</button>
							</div>

							<div class="flex-1 space-y-3">
								<input
									type="text"
									bind:value={step.title}
									class="input"
									placeholder="步骤标题"
								/>
								<textarea
									bind:value={step.description}
									class="input min-h-[80px]"
									placeholder="步骤说明和操作要点..."
								/>
								<div class="grid grid-cols-2 gap-3">
									<div>
										<label class="label">参考视频URL</label>
										<input
											type="url"
											bind:value={step.video_url ?? ''}
											class="input text-sm"
											placeholder="https://..."
										/>
									</div>
									<div>
										<label class="label">建议时长（秒）</label>
										<input
											type="number"
											bind:value={step.duration_seconds}
											min="0"
											class="input text-sm"
										/>
									</div>
								</div>
							</div>

							<button
								on:click={() => removeStep(index)}
								class="p-2 text-gray-400 hover:text-red-500 hover:bg-red-50 rounded-lg"
							>
								<Trash2 class="w-5 h-5" />
							</button>
						</div>
					</div>
				{/each}
			</div>
		{/if}
	</div>

	<div class="flex justify-end gap-3">
		<button on:click={() => history.back()} class="btn btn-secondary">
			取消
		</button>
		<button on:click={saveTemplate} class="btn btn-primary" disabled={loading}>
			<Save class="w-5 h-5 mr-2" />
			{loading ? '保存中...' : '保存模板'}
		</button>
	</div>
</div>
